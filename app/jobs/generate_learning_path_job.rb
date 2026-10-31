class GenerateLearningPathJob < ApplicationJob
  FAILURE_MESSAGE = "We couldn't build this path. Please try again.".freeze

  queue_as :default
  # The path may have been deleted before the job ran; nothing left to do.
  discard_on ActiveJob::DeserializationError

  def perform(learning_path)
    return unless learning_path.generating?

    result = generate(learning_path.learning_goal)
    CheckLinksJob.perform_later(learning_path) if save_result(learning_path, result)
  rescue PathGenerator::Error => e
    mark_failed(learning_path, e)
  rescue StandardError => e
    # Don't leave the user looking at a spinner forever; re-raise so the error
    # is still reported, unless the path was simply deleted while we worked.
    mark_failed(learning_path, e)
    raise if LearningPath.exists?(learning_path.id)
  ensure
    refresh_and_broadcast(learning_path)
  end

  private
    # Models occasionally return malformed JSON, so a bad answer gets one more try.
    def generate(goal)
      attempts = 0
      begin
        attempts += 1
        PathGenerator.call(goal)
      rescue PathGenerator::InvalidOutput => e
        Rails.logger.warn("[GenerateLearningPathJob] invalid output on attempt #{attempts}: #{e.message}")
        retry if attempts < 2
        raise
      end
    end

    # The generator call can take a while, so the path is re-read under a lock
    # first: it may have been deleted, or a newer job (e.g. from a double-clicked
    # "Regenerate") may already have filled it. Either way this result is
    # dropped. Returns true when the steps were saved.
    def save_result(learning_path, result)
      LearningPath.transaction do
        current = LearningPath.lock.find_by(id: learning_path.id)
        next false unless current&.generating?

        current.path_steps.delete_all
        result.steps.each.with_index(1) do |step, position|
          current.path_steps.create!(step.merge(position: position))
        end
        current.update!(
          title: result.title,
          summary: result.summary,
          skills: result.skills,
          raw_response: result.raw,
          generated_at: Time.current,
          error_message: nil,
          status: :ready
        )
        true
      end
    end

    # Only a path that is still generating is marked failed, so a late failure
    # can't clobber a path that a newer job already finished.
    def mark_failed(learning_path, error)
      Rails.logger.error("[GenerateLearningPathJob] path #{learning_path.id} failed: #{error.class}: #{error.message}")
      LearningPath.where(id: learning_path.id, status: LearningPath.statuses[:generating]).update_all(
        status: LearningPath.statuses[:failed],
        error_message: FAILURE_MESSAGE,
        raw_response: error.try(:raw),
        updated_at: Time.current
      )
    end

    # Reload so the broadcast shows what is really saved, not attributes left
    # over from a rolled-back save. A deleted path has nothing left to show.
    def refresh_and_broadcast(learning_path)
      learning_path.reload.broadcast_refresh
    rescue ActiveRecord::RecordNotFound
      Rails.logger.info("[GenerateLearningPathJob] path #{learning_path.id} was deleted while generating")
    end
end
