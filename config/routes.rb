Rails.application.routes.draw do
  root "home#welcome"
  get "help", to: "home#help", as: :help

  # Health check route
  get "up" => "rails/health#show", as: :rails_health_check

  # Devise authentication routes
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
  devise_scope :user do
    get "users/sign_in", to: "users/sessions#new", as: :new_user_session
    delete "users/sign_out", to: "users/sessions#destroy", as: :destroy_user_session
  end

  get "complete_profile", to: "users#complete_profile"
  patch "complete_profile", to: "users#update_profile"

  # Nested resources for plant_modules
  resources :plant_modules do
    resources :control_signals, only: [ :edit, :update ] do
      post :trigger, on: :member
    end
    resources :sensors, only: [ :index, :show, :create, :new ] do
      member do
        patch :toggle_notification
        patch :update_notification_settings
        get :load_notification_settings
      end
    end
    resources :schedules
  end


  # Add routes for the plants page (for interactive plant selection/overrides)
  resources :plants, only: [ :index, :show ] do
    member do
      get :info
    end
  end

  # Time series data routes
  resources :time_series_data, only: [ :index, :show ]

  get "sensors/:id/time_series", to: "sensors#show", as: :sensor_time_series
  get "sensors/:id/time_series_chart", to: "sensors#time_series_chart", as: :sensor_time_series_chart

  post "mqtt/schedule", to: "mqtt#set_schedule" # TODO: delete
  post "mqtt/water", to: "mqtt#send_water_signal"

  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker # TODO: push notifications (this needed?)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  mount ActionCable.server => "/cable"
end
