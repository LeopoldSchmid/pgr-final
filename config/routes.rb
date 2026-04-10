Rails.application.routes.draw do
  # Locale-aware routes
  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    get "timeline" => "timeline#index", as: :timeline
    get "favorite_locations" => "favorite_locations#index", as: :favorite_locations
    get "search" => "search#index", as: :search
    get "search/global" => "search#global", as: :global_search
    
    # User's invitation inbox (specific route to avoid conflict)
    get 'invitations' => 'invitations#index', as: :user_invitations
    
    # Authentication routes
    resource :session
    resources :passwords, param: :token
    resources :registrations, only: [:new, :create]
    
    # Profile routes
    get "profile" => "profile#show"
    patch "profile" => "profile#update"

    # Trip Switcher routes
    get 'select_trip' => 'trip_switcher#index', as: :select_trip
    patch 'switch_trip' => 'trip_switcher#update', as: :switch_trip
    delete 'clear_trip_context' => 'trip_switcher#destroy', as: :clear_trip_context

    # Feature-based navigation routes (auto-scoped to current trip)
    # Plans section
    get 'plans' => 'plans#index', as: :plans
    get 'plans/meals' => 'plans#meals', as: :plans_meals
    get 'plans/shopping' => 'shopping_plans#show', as: :plans_shopping
    post 'plans/shopping/sync' => 'shopping_plans#sync', as: :plans_shopping_sync
    post 'plans/shopping/manual_requirement' => 'shopping_plans#create_manual_requirement', as: :plans_shopping_manual_requirement
    post 'plans/shopping/undo/:id' => 'shopping_plans#undo_sync', as: :plans_shopping_undo_sync
    post 'plans/shopping/requirements/:requirement_id/assignments' => 'shopping_plans#create_assignment', as: :plans_shopping_requirement_assignments
    get 'plans/shopping-list' => 'shopping_lists#current', as: :plans_shopping_list
    get 'plans/packing' => 'plans#packing', as: :plans_packing
    get 'plans/itinerary' => 'plans#itinerary', as: :plans_itinerary
    get 'plans/templates' => 'plans#templates', as: :plans_templates

    # Meal plans (context-based, no trip_id)
    resources :meal_plans, only: [:create, :update, :destroy]

    # Memories section
    get 'memories' => 'memories#index', as: :memories
    get 'memories/albums' => 'memories#albums', as: :memories_albums
    get 'memories/map' => 'memories#map', as: :memories_map
    get 'memories/favorites' => 'memories#favorites', as: :memories_favorites

    # Home section
    get 'home/calendar' => 'home#calendar', as: :home_calendar
    get 'home/upcoming' => 'home#upcoming', as: :home_upcoming

    # Context-based expenses routes
    resources :expenses, only: [:index, :new, :create, :edit, :update, :destroy] do
      member do
        patch :toggle_settled
        get :duplicate
      end
    end
    # Expenses secondary navigation
    get 'expenses/by-person' => 'expenses#by_person', as: :expenses_by_person
    get 'expenses/by-category' => 'expenses#by_category', as: :expenses_by_category
    get 'expenses/settle' => 'expenses#settle', as: :expenses_settle
    get 'expenses/summary' => 'expenses#summary', as: :expenses_summary

    # Context-based trip hub pages (NEW structure)
    get 'trip' => 'trips#overview', as: :trip_overview
    get 'trip/dates' => 'trips#dates', as: :trip_dates
    get 'trip/details' => 'trips#details', as: :trip_details
    get 'trip/participants' => 'trips#participants', as: :trip_participants
    get 'trip/discussions' => 'discussions#index', as: :trip_discussions
    # Redirect old routes to new structure
    get 'trip/meal_plans', to: redirect { |params, request| "/#{params[:locale]}/plans/meals" }
    get 'trip/recipes' => 'recipes#index', as: :trip_recipes_context

    # Legacy context-based routes (redirect to new structure)
    get 'trip/plan' => 'trips#plan', as: :trip_plan_context
    get 'trip/go' => 'trips#go', as: :trip_go_context
    get 'trip/reminisce' => 'trips#reminisce', as: :trip_reminisce_context

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
    end
    
    # Shopping lists nested under trips
    resources :shopping_lists, only: [:index, :show, :create, :update] do
      member do
        post :generate_from_meal_plan
        post :add_manual_item
      end
      collection do
        get :current
      end
      resources :shopping_items, only: [:create, :update, :destroy] do
        member do
          patch :toggle_purchased
          patch :record_purchase
        end
      end
      resources :shopping_list_assignments, only: [] do
        member do
          patch :record_purchase
          patch :mark_complete
          patch :clear_purchase
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
    get 'recipes/:id' => 'recipe_library#show', as: :recipe
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
