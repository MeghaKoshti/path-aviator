# Weekly (config/recurring.yml): Pro users get their active paths' links
# checked again, so a page that disappears later is caught and replaced too.
class RecheckLinksJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      next unless user.weekly_link_recheck?

      user.learning_paths.ready.find_each do |path|
        CheckLinksJob.perform_later(path) unless path.completed?
      end
    end
  end
end
