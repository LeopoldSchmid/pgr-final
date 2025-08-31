# app/controllers/pwa_controller.rb
class PwaController < ApplicationController
  skip_before_action :require_authentication # Service worker doesn't need authentication

  def service_worker
    # Read the content of your custom service worker file
    service_worker_content = Rails.root.join('app', 'javascript', 'custom_service_worker.js').read
    
    # Render it with the correct content type
    render plain: service_worker_content, content_type: 'application/javascript'
  end
end