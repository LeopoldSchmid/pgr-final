class Api::TripsController < ApplicationController
  before_action :require_authentication
  before_action :set_trip

  def calendar_events
    events = []
    
    # Add date proposals
    @trip.date_proposals.includes(:user, :date_proposal_votes).each do |proposal|
      vote_summary = proposal.vote_summary
      user_vote = proposal.user_vote(Current.user)
      title = proposal.title.present? ? "##{proposal.id}: #{proposal.title}" : "##{proposal.id}"
      
      events << {
        id: "proposal_#{proposal.id}",
        title: title,
        start: proposal.start_date.to_s,
        end: (proposal.end_date + 1.day).to_s, # FullCalendar expects exclusive end date
        type: 'proposal',
        backgroundColor: '#BEC8F9',
        borderColor: '#7A83B3',
        textColor: '#1C1C1E',
        extendedProps: {
          type: 'proposal',
          proposalId: proposal.id,
          title: proposal.title,
          proposer: proposal.user.email_address,
          votes: vote_summary,
          userVote: user_vote,
          description: proposal.description,
          notes: proposal.notes,
          deletable: proposal.user == Current.user || @trip.user_can_manage_expenses?(Current.user)
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
          title: availability.title.present? ? availability.title : "Availability ##{availability.id}",
          start: availability.start_date.to_s,
          end: (availability.end_date + 1.day).to_s,
          type: availability.availability_type,
          backgroundColor: color[:bg],
          borderColor: color[:border],
          textColor: '#1C1C1E',
          extendedProps: {
            type: availability.availability_type,
            availabilityId: availability.id,
            userId: user.id,
            userName: user.email_address,
            title: availability.title,
            description: availability.description,
            deletable: availability.user == Current.user
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
      { bg: '#E4A094', border: '#D09484' } # accent-red
    when 'busy'
      { bg: '#DDCA7E', border: '#D0B64F' } # accent-yellow
    when 'preferred'
      { bg: '#A9B9A2', border: '#94A68F' } # accent-green
    else
      { bg: '#EFE2DB', border: '#E1CEC7' } # accent-brown
    end
  end
end