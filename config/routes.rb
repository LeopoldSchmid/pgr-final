Rails.application.routes.draw do
  # Locale-aware routes
  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    get "timeline" => "timeline#index", as: :timeline
    get "favorite_locations" => "favorite_locations#index", as: :favorite_locations
    get "search" => "search#index", as: :search
    
    # User's invitation inbox (specific route to avoid conflict)
    get 'invitations' => 'invitations#index', as: :user_invitations
    
    # Authentication routes
    resource :session
    resources :passwords, param: :token
    resources :registrations, only: [:new, :create]
    
    # Profile routes
    get "profile" => "profile#show"
    patch "profile" => "profile#update"
    
    # Trip resources
    resources :trips do
    # Trip-specific phase routes (Hub pages)
    get :plan, on: :member
    get :go, on: :member  
    get :reminisce, on: :member
    get :report, on: :member
    get :download_photos, on: :member
    
    # Single-function pages (Spoke pages)
    get :capture, on: :member
    get :journal, on: :member
    get :map, on: :member
    get :gallery, on: :member
    
    resources :date_proposals, only: [:index, :create, :destroy, :update, :edit]
    resources :date_proposal_votes, only: [:create, :update, :destroy]
    resources :user_availabilities, only: [:index, :create, :update, :destroy]
    
    # Journal entries nested under trips
    resources :journal_entries, except: [:show, :index] do
      patch :toggle_favorite, on: :member
      delete :bulk_destroy, on: :collection
      get :bulk_export, on: :collection
      resources :comments, only: [:create, :destroy]
      resource :journal_entry_vote, only: [:create], path: 'vote'
    end
    
    # Expenses nested under trips
    resources :expenses, except: [:show] do
      member do
        patch :toggle_settled
        get :duplicate
      end
    end
    
    # Invitations nested under trips
    resources :invitations, only: [:new, :create, :index, :destroy]
    resources :trip_attachments, only: [:create, :update, :destroy] do
      resources :trip_attachment_comments, only: [:create, :destroy], path: 'comments'
      resource :trip_attachment_vote, only: [:create], path: 'vote'
    end
    
    # Discussions nested under trips
    resources :discussions do
      member do
        post :upvote
        post :downvote
      end
      resources :discussion_replies, only: [:create, :destroy] do
        member do
          post :upvote
          post :downvote
        end
      end
    end
    
    # Recipes nested under trips
    resources :recipes do
      member do
        patch :toggle_selected
      end
    end
    
    # Shopping lists nested under trips
    resources :shopping_lists, only: [:index, :show, :create, :update] do
      member do
        post :generate_from_recipes
        post :add_manual_item
      end
      resources :shopping_items, only: [:create, :update, :destroy] do
        member do
          patch :toggle_purchased
        end
      end
    end
  end
  
    # Global phase routes
    get "plan" => "phases#plan"
    get "go" => "phases#go"
    get "reminisce" => "phases#reminisce"
    
    # Recipe library (browse all recipes)
    get 'recipes' => 'recipe_library#index', as: :recipe_library
    get 'recipes/search' => 'recipe_library#search_suggestions', as: :recipe_search_suggestions
    post 'recipes/:id/copy' => 'recipe_library#copy', as: :copy_recipe
    
    # Main application routes
    root "home#index"
  end
  
  # Routes outside of locale scope
  
  # Standalone invitation routes (for accepting via email links) - keep outside locale for email compatibility
  resources :invitations, only: [:show], param: :token do
    member do
      get :accept
      get :decline
      patch :accept
      patch :decline
    end
  end
  
  # API routes - keep outside locale scope
  namespace :api do
    resources :food_items, only: [] do
      collection do
        get :search
      end
    end
    
    # Calendar API endpoints
    resources :trips, only: [] do
      member do
        get :calendar_events
      end
    end
  end

  # Health check for load balancers
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA files
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "pwa#service_worker", as: :pwa_service_worker
end
