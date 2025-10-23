ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    # fixtures :all

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
end