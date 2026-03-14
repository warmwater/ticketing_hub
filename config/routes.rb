Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  # Language switcher
  patch "locale", to: "locale#update"

  root "home#index"

  # Public event browsing
  resources :events, only: [ :index, :show ] do
    resource :waiting_room, only: [ :show, :create, :destroy ], controller: "waiting_rooms" do
      get :status
    end
    resources :orders, only: [ :new, :create ] do
      collection do
        get :select_seats
      end
    end
  end

  resources :orders, only: [ :index, :show ]
  resources :tickets, only: [ :index, :show ]

  # Turbo Native path configuration
  get "/turbo-native/path-configuration", to: "turbo_native#path_configuration", as: :turbo_native_path_configuration

  # Admin namespace
  namespace :admin do
    root "dashboard#index"
    resources :venues do
      resources :sections, only: [ :create, :update, :destroy ], controller: "venue_sections" do
        member do
          post :generate_seats
        end
      end
    end
    resources :users do
      member do
        patch :update_role
      end
    end
    resources :events do
      member do
        patch :publish
        patch :cancel
        delete :purge_attachment
      end
    end
  end

  # Organizer namespace
  namespace :organizer do
    root "dashboard#index"
    resources :events do
      member do
        patch :publish
        patch :cancel
        patch :toggle_waiting_room
        delete :purge_attachment
      end
      resources :ticket_types
    end
    resources :orders, only: [ :index, :show ]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
