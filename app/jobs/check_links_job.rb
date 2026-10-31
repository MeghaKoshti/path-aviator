# Opens every step's link on a path and records what happened (see LinkChecker).
# Runs right after a path is generated, and weekly for Pro users (RecheckLinksJob).
#
# A broken link gets one substitute from the generator per run. If the
# substitute is broken too, the step keeps its link and is flagged, and the
# page offers a search instead.
class CheckLinksJob < ApplicationJob
  queue_as :default
  discard_on ActiveJob::DeserializationError

  def perform(learning_path, checker: LinkChecker.default)
    return unless learning_path.ready?

    @checker = checker
    learning_path.path_steps.each { |step| check_step(step) }
  end

  private
    def check_step(step)
      result = @checker.check(step.resource_url)
      changes = { link_status: result.status.to_s, link_checked_at: Time.current }
      changes.merge!(substitute_for(step)) if result.broken?

      # Only write if the step still has the link we checked: the path may have
      # been regenerated (or the step deleted) while we were waiting on the network.
      saved = PathStep.where(id: step.id, resource_url: step.resource_url).update_all(changes.merge(updated_at: Time.current))
      broadcast(step.reload) if saved.positive?
    rescue ActiveRecord::RecordNotFound
      nil
    end

    # The attributes to save when the generator found a link that works, or
    # nothing (the step stays broken) when it didn't.
    def substitute_for(step)
      replacement = PathGenerator.replace_step(step)
      result = @checker.check(replacement.resource_url)
      return {} if result.broken?

      {
        link_status: result.status.to_s,
        description: replacement.description,
        resource_type: replacement.resource_type,
        resource_url: replacement.resource_url
      }
    rescue PathGenerator::Error => e
      Rails.logger.warn("[CheckLinksJob] no substitute for step #{step.id}: #{e.class}: #{e.message}")
      {}
    end

    # Swaps just the step's link and badge, so a note being edited isn't lost.
    def broadcast(step)
      user = step.learning_path.user
      Time.use_zone(user.zone) do
        step.broadcast_replace_to [ user, :learning_paths ],
          target: ActionView::RecordIdentifier.dom_id(step, :resource),
          partial: "path_steps/resource",
          locals: { path_step: step }
      end
    end
end
