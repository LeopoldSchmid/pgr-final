# frozen_string_literal: true

module TripsHelper
  def status_badge_class(status)
    case status
    when "planning"
      "bg-blue-100 text-blue-800"
    when "active"
      "bg-green-100 text-green-800"
    when "completed"
      "bg-gray-100 text-gray-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end
end