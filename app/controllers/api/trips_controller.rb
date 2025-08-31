class Api::TripsController < ApplicationController
  before_action :require_authentication
  before_action :set_trip

  def calendar_events
    events = []
    
    # Add date proposals
    @trip.date_proposals.includes(:user, :date_proposal_votes).each do |proposal|
      vote_summary = proposal.vote_summary
      user_vote = proposal.user_vote(Current.user)
      
      events << {
        id: "proposal_#{proposal.id}",
        title: "#{proposal.user.email_address.split('@').first}'s proposal",
        start: proposal.start_date,
        end: proposal.end_date + 1.day, # FullCalendar expects exclusive end date
        type: 'proposal',
        backgroundColor: '#10b981',
        borderColor: '#059669',
        textColor: '#ffffff',
        extendedProps: {
          type: 'proposal',
          proposalId: proposal.id,
          proposer: proposal.user.email_address,
          votes: vote_summary,
          userVote: user_vote,
          description: proposal.description,
          notes: proposal.notes
        }
      }
    end
    
    # Add user availabilities for all trip members
    all_trip_users = [@trip.user] + @trip.active_members
    all_trip_users.each do |user|
      user.user_availabilities.each do |availability|
        next unless availability_overlaps_trip_timeframe?(availability)
        
        color = availability_color(availability.availability_type)
        
        events << {
          id: "availability_#{availability.id}",
          title: "#{availability.display_title} (#{user.email_address.split('@').first})",
          start: availability.start_date,
          end: availability.end_date + 1.day,
          type: availability.availability_type,
          backgroundColor: color[:bg],
          borderColor: color[:border],
          textColor: '#ffffff',
          extendedProps: {
            type: availability.availability_type,
            availabilityId: availability.id,
            userId: user.id,
            userName: user.email_address,
            description: availability.description
          }
        }
      end
    end
    
    render json: events
  end

  private

  def set_trip
    @trip = Current.user.trips.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    # Check if user is a member
    member_trips = Trip.joins(:trip_members)
                      .where(trip_members: { user: Current.user }, id: params[:id])
    @trip = member_trips.first
    
    unless @trip
      render json: { error: "Trip not found or access denied" }, status: :not_found
    end
  end

  def availability_overlaps_trip_timeframe?(availability)
    # Show availabilities that are relevant to the trip planning timeframe
    # For now, show all availabilities. Could be filtered based on trip dates or a planning window
    true
  end

  def availability_color(availability_type)
    case availability_type
    when 'unavailable'
      { bg: '#ef4444', border: '#dc2626' }
    when 'busy'
      { bg: '#6b7280', border: '#4b5563' }
    when 'preferred'
      { bg: '#f59e0b', border: '#d97706' }
    else
      { bg: '#6b7280', border: '#4b5563' }
    end
  end
end