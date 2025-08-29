Rails.application.routes.draw do
  # Authentication routes
  resource :session
  resources :passwords, param: :token
  resources :registrations, only: [:new, :create]
  
  # Trip resources
  resources :trips do
    # Trip-specific phase routes
    get :plan, on: :member
    get :go, on: :member  
    get :reminisce, on: :member
    
    # Journal entries nested under trips
    resources :journal_entries, except: [:show, :index] do
      patch :toggle_favorite, on: :member
    end
  end
  
  # Global phase routes
  get "plan" => "phases#plan"
  get "go" => "phases#go"
  get "reminisce" => "phases#reminisce"
  
  # Main application routes
  root "home#index"

  # Health check for load balancers
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA files
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
