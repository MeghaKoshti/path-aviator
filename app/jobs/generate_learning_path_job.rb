class GenerateLearningPathJob < ApplicationJob
  FAILURE_MESSAGE = "We couldn't build this path. Please try again.".freeze

  queue_as :default
  # The path may have been deleted before the job ran; nothing left to do.
  discard_on ActiveJob::DeserializationError

  def perform(learning_path)
    return unless learning_path.generating?

    result = generate(learning_path.learning_goal)
    save_result(learning_path, result)
  rescue PathGenerator::Error => e
    mark_failed(learning_path, e)
  rescue StandardError => e
    # Don't leave the user looking at a spinner forever; re-raise so the error is still reported.
    mark_failed(learning_path, e)
    raise
  ensure
    learning_path.broadcast_refresh
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

    def save_result(learning_path, result)
      LearningPath.transaction do
        learning_path.path_steps.delete_all
        result.steps.each.with_index(1) do |step, position|
          learning_path.path_steps.create!(step.merge(position: position))
        end
        learning_path.update!(
          title: result.title,
          summary: result.summary,
          raw_response: result.raw,
          generated_at: Time.current,
          error_message: nil,
          status: :ready
        )
      end
      learning_path.reload
    end

    def mark_failed(learning_path, error)
      Rails.logger.error("[GenerateLearningPathJob] path #{learning_path.id} failed: #{error.class}: #{error.message}")
      learning_path.update_columns(
        status: LearningPath.statuses[:failed],
        error_message: FAILURE_MESSAGE,
        raw_response: error.try(:raw),
        updated_at: Time.current
      )
      # Drop any attributes left over from a rolled-back save before broadcasting.
      learning_path.reload
    end
end
