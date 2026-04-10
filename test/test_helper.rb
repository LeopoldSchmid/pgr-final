ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: ENV.fetch("PARALLEL_WORKERS", "1").to_i)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    # Opt in per test file so fixture-heavy tests do not pollute record counts globally.

    # Add more helper methods to be used by all tests here...
  end
end

# Test helpers for mocking authentication
module TestAuthenticationHelpers
  def sign_in_as(user)
    mock_session = Object.new
    mock_session.define_singleton_method(:user) { user }
    Current.session = mock_session
  end

  def sign_out
    Current.session = nil
  end
end

class ActiveSupport::TestCase
  include TestAuthenticationHelpers

  setup do
    Current.reset
  end

  teardown do
    Current.reset
  end
end

class ActionDispatch::IntegrationTest
  setup do
    Current.reset
  end

  teardown do
    Current.reset
  end
end
