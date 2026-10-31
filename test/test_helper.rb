ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require "minitest/mock"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Every test starts with fresh rate-limit counters (see config/environments/test.rb).
    setup { ActionController::Base.cache_store.clear }

    # Pro-only features, before and after billing adds User#pro?.
    def as_pro(&block)
      ProAccess.stub(:granted?, true, &block)
    end
  end
end

class ActionDispatch::IntegrationTest
  include SessionTestHelper
end
