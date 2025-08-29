class PhasesController < ApplicationController
  before_action :require_authentication
  
  def plan
    @planning_trips = Current.user.trips.planning
    @recent_templates = Current.user.trips.completed.limit(3)
  end

  def go
    @active_trips = Current.user.trips.active
  end

  def reminisce
    @completed_trips = Current.user.trips.completed
  end
end
