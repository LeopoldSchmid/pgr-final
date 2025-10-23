class TripsController < ApplicationController
  before_action :require_authentication
  before_action :set_trip, only: [:show, :edit, :update, :destroy, :plan, :go, :reminisce, :capture, :journal, :map, :gallery]

  def index
    # Include trips user owns + trips user is a member of
    all_user_trips = (Current.user.trips + Trip.joins(:trip_members).where(trip_members: { user: Current.user })).uniq.sort_by(&:created_at).reverse

    @planning_trips = all_user_trips.select(&:planning?)
    @active_trips = all_user_trips.select(&:active?)
    @completed_trips = all_user_trips.select(&:completed?)

    # Fetch global favorite locations for the current user
    user_favorite_locations = JournalEntry.where(user: Current.user, global_favorite: true, latitude: true, longitude: true)
                                          .pluck(:latitude, :longitude)
                                          .map { |lat, lon| [lat.to_f, lon.to_f] }
                                          .uniq

    @recommended_trips = []
    if user_favorite_locations.any?
      # Find other trips that have journal entries with similar locations
      # This is a simplified recommendation: find trips with at least one shared favorite location
      Trip.where.not(id: all_user_trips.map(&:id)).each do |other_trip|
        other_trip_locations = other_trip.journal_entries.where(latitude: true, longitude: true)
                                         .pluck(:latitude, :longitude)
                                         .map { |lat, lon| [lat.to_f, lon.to_f] }
                                         .uniq

        # Check for any overlap in locations
        if (user_favorite_locations & other_trip_locations).any?
          @recommended_trips << other_trip
        end
      end
    end
  end

  def show
    # Redirect to appropriate phase view
    redirect_to send("#{@trip.current_phase}_trip_path", @trip)
  end

  def new
    @trip = Current.user.trips.build
    @user_trips = Current.user.trips.order(name: :asc)
  end

  def create
    @trip = Current.user.trips.build(trip_params.except(:template_trip_id))

    if params[:trip][:template_trip_id].present?
      template_trip = Current.user.trips.find(params[:trip][:template_trip_id])
      @trip.name = "#{template_trip.name} (Copy)" unless @trip.name.present?
      @trip.description = template_trip.description unless @trip.description.present?
      @trip.series_name = template_trip.series_name unless @trip.series_name.present?
    end
    
    if @trip.save
      if template_trip.present?
        # Copy recipes
        template_trip.recipes.each do |recipe|
          new_recipe = recipe.dup
          new_recipe.trip = @trip
          new_recipe.save
        end
        # TODO: Copy shopping lists, journal entries (content only), etc.
      end
      redirect_to plan_trip_path(@trip), notice: 'Trip created successfully!'
    else
      @user_trips = Current.user.trips.order(name: :asc) # Re-fetch for rendering new template
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @trip.update(trip_params)
      redirect_to @trip, notice: 'Trip updated successfully!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @trip.destroy
    redirect_to trips_path, notice: 'Trip deleted successfully!'
  end

  # Trip-level phase views
  def plan
    # Trip planning view - dates, destinations, meals, etc.
    @related_trips = @trip.series_name.present? ? Trip.in_series(@trip.series_name).where.not(id: @trip.id) : []
    @date_proposals = @trip.date_proposals.order(:start_date)
  end

  def go
    # Trip execution view - shopping lists, expenses, day-of activities
    @journal_entries = @trip.journal_entries.by_date.includes(:user)
    @new_journal_entry = @trip.journal_entries.build(entry_date: Date.current)
    @related_trips = @trip.series_name.present? ? Trip.in_series(@trip.series_name).where.not(id: @trip.id) : []
  end

  def reminisce
    # Trip memories view - photos, summaries, templates
    @journal_entries = @trip.journal_entries.by_date.includes(:user)
    @favorite_moments = @trip.favorite_moments
    @journal_summary = @trip.journal_summary
    @entries_with_images = @trip.journal_entries.with_images.recent
    @entries_with_locations = @trip.journal_entries.with_location.includes(:user)
    @related_trips = @trip.series_name.present? ? Trip.in_series(@trip.series_name).where.not(id: @trip.id) : []
  end

  # Single-function spoke pages
  def capture
    # Focused capture experience
    @new_journal_entry = @trip.journal_entries.build(entry_date: Date.current)
  end

  def journal
    # Focused journal viewing
    @journal_entries = @trip.journal_entries.by_date.includes(:user)
    @search_query = params[:search]
    if @search_query.present?
      @journal_entries = @journal_entries.where("LOWER(content) LIKE LOWER(?) OR LOWER(location) LIKE LOWER(?)", "%#{@search_query}%", "%#{@search_query}%")
    end
  end

  def map
    # Focused map experience
    @journal_entries = @trip.journal_entries.with_location.includes(:user)
  end

  def gallery
    # Focused photo gallery
    @entries_with_images = @trip.journal_entries.with_images.by_date.includes(:user)
  end

  def report
    @journal_entries = @trip.journal_entries.by_date.includes(:user)
    @expenses = @trip.expenses.includes(:payer)

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "Trip Report - #{@trip.name}",
               template: "trips/report",
               layout: "pdf", # Use a custom layout for PDF
               disposition: "attachment" # or "inline" to display in browser
      end
    end
  end

  def download_photos
    # Ensure only images belonging to the current trip are included
    images = @trip.journal_entries.includes(images_attachments: :blob).flat_map(&:images).compact

    if images.empty?
      redirect_to reminisce_trip_path(@trip), alert: "No photos found for this trip."
      return
    end

    # Create a temporary zip file
    zip_file_path = Rails.root.join("tmp", "#{@trip.name.parameterize}-photos-#{Time.zone.now.to_i}.zip")

    Zip::File.open(zip_file_path, Zip::File::CREATE) do |zipfile|
      images.each_with_index do |image, index|
        # Use a unique name for each file in the zip
        filename = "#{image.filename.base}.#{image.filename.extension}"
        # Ensure unique filenames in case of duplicates
        entry_name = "#{index + 1}_#{filename}"
        zipfile.add(entry_name, ActiveStorage::Blob.service.path_for(image.key))
      end
    end

    send_file zip_file_path,
              type: 'application/zip',
              disposition: 'attachment',
              filename: File.basename(zip_file_path)
  ensure
    # Clean up the temporary zip file
    File.delete(zip_file_path) if File.exist?(zip_file_path)
  end

  private

  def set_trip
    # Find trips user owns OR is a member of
    owned_trips = Current.user.trips.where(id: params[:id])
    member_trips = Trip.joins(:trip_members)
                      .where(trip_members: { user: Current.user }, id: params[:id])
    
    trip_relation = Trip.where(id: [owned_trips.pluck(:id) + member_trips.pluck(:id)].flatten)
    @trip = trip_relation.first
    
    raise ActiveRecord::RecordNotFound unless @trip
  end

  def trip_params
    params.require(:trip).permit(:name, :description, :start_date, :end_date, :series_name, :template_trip_id)
  end
end
