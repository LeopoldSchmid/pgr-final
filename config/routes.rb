Rails.application.routes.draw do
  # Standalone invitation routes (for accepting via email links)
  resources :invitations, only: [:show], param: :token do
    member do
      patch :accept
      patch :decline
    end
  end
  
  # User's invitation inbox (specific route to avoid conflict)
  get 'invitations' => 'invitations#index', as: :user_invitations
  
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
    
    # Expenses nested under trips
    resources :expenses, except: [:show] do
      member do
        patch :toggle_settled
        get :duplicate
      end
    end
    
    # Invitations nested under trips
    resources :invitations, only: [:new, :create, :index, :destroy]
    
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
  
  # API routes
  namespace :api do
    resources :food_items, only: [] do
      collection do
        get :search
      end
    end
  end
  
  # Main application routes
  root "home#index"

  # Health check for load balancers
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA files
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
