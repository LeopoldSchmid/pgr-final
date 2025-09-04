class JournalEntriesController < ApplicationController
  before_action :require_authentication
  before_action :set_trip
  before_action :set_journal_entry, only: [:edit, :update, :destroy, :toggle_favorite]

  def create
    Rails.logger.debug "=== JournalEntriesController#create called ==="
    Rails.logger.debug "Params: #{params.inspect}"
    Rails.logger.debug "Trip: #{@trip.name}"
    Rails.logger.debug "User: #{Current.user.email_address}"
    
    @journal_entry = @trip.journal_entries.build(journal_entry_params)
    @journal_entry.user = Current.user
    @journal_entry.entry_date ||= Date.current
    
    Rails.logger.debug "Journal entry built: #{@journal_entry.inspect}"
    Rails.logger.debug "Journal entry valid?: #{@journal_entry.valid?}"
    Rails.logger.debug "Journal entry errors: #{@journal_entry.errors.full_messages}"
    
    if @journal_entry.save
      redirect_to go_trip_path(@trip), notice: 'Journal entry added! 📝'
    else
      Rails.logger.error "Failed to save journal entry: #{@journal_entry.errors.full_messages}"
      redirect_to go_trip_path(@trip), alert: "Could not save journal entry: #{@journal_entry.errors.full_messages.join(', ')}"
    end
  end

  def edit
    # Journal entry is loaded by before_action
  end

  def update
    # Handle images separately to avoid overwriting existing images with empty array
    update_params = journal_entry_params.except(:images, :images_to_delete)
    
    if @journal_entry.update(update_params)
      # Delete marked images
      if params[:journal_entry][:images_to_delete].present?
        image_ids_to_delete = params[:journal_entry][:images_to_delete].split(',').map(&:to_i)
        @journal_entry.images.where(id: image_ids_to_delete).each(&:purge)
      end
      
      # Only add new images if provided
      if params[:journal_entry][:images].present? && params[:journal_entry][:images].reject(&:blank?).any?
        @journal_entry.images.attach(params[:journal_entry][:images].reject(&:blank?))
      end
      
      flash[:alert_message] = 'Journal entry updated! ✏️'
      redirect_to journal_trip_path(@trip)
    else
      render :edit
    end
  end

  def destroy
    @journal_entry.destroy
    redirect_to go_trip_path(@trip), notice: 'Journal entry deleted! 🗑️'
  end

  def toggle_favorite
    @journal_entry.toggle_favorite!
    status = @journal_entry.favorite? ? 'Added to favorites! ⭐' : 'Removed from favorites'
    redirect_to go_trip_path(@trip), notice: status
  end

  def bulk_destroy
    # Ensure only entries belonging to the current trip and user are destroyed
    @trip.journal_entries.where(id: params[:journal_entry_ids]).destroy_all
    redirect_to go_trip_path(@trip), notice: 'Selected journal entries deleted! 🗑️'
  end

  def bulk_export
    @journal_entries = @trip.journal_entries.where(id: params[:ids])

    respond_to do |format|
      format.csv do
        send_data generate_csv(@journal_entries), filename: "journal_entries_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}.csv"
      end
      format.json do
        render json: @journal_entries.to_json(
          only: [:id, :content, :location, :latitude, :longitude, :entry_date, :favorite, :category, :created_at, :updated_at],
          include: { user: { only: [:email_address] } }
        )
      end
    end
  end


  private

  def generate_csv(journal_entries)
    CSV.generate(headers: true) do |csv|
      csv << ["ID", "Content", "Location", "Latitude", "Longitude", "Entry Date", "Favorite", "Category", "Created At", "Updated At"]
      journal_entries.each do |entry|
        csv << [entry.id, entry.content, entry.location, entry.latitude, entry.longitude, entry.entry_date, entry.favorite, entry.category, entry.created_at, entry.updated_at]
      end
    end
  end

  private

  def set_trip
    @trip = Current.user.trips.find(params[:trip_id])
  end

  def set_journal_entry
    @journal_entry = @trip.journal_entries.find(params[:id])
  end

  def journal_entry_params
    params.require(:journal_entry).permit(:content, :location, :entry_date, :favorite, :latitude, :longitude, :category, :global_favorite, :images_to_delete, images: [])
  end
end
