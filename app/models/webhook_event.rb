# A webhook delivery we accepted. The unique (provider, event_id) index is
# what makes processing idempotent: a retry of the same event can't be saved
# twice, so it is never applied twice.
class WebhookEvent < ApplicationRecord
  validates :provider, :event_id, presence: true
end
