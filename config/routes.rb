Rails.application.routes.draw do
  root "home#welcome"

  # Health check route
  get "up" => "rails/health#show", as: :rails_health_check

  # Devise authentication routes
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
  devise_scope :user do
    get "users/sign_in", to: "users/sessions#new", as: :new_user_session
    get "users/sign_out", to: "users/sessions#destroy", as: :destroy_user_session
  end

  # Nested resources for plant_modules
  resources :plant_modules do
    resources :control_signals, only: [ :edit, :update ]
    resources :sensors, only: [ :index, :show, :create, :new ] do
      member do
        patch :toggle_notification
        patch :update_notification_settings
      end
    end
    resources :schedules
  end


  # Add routes for the plants page (for interactive plant selection/overrides)
  resources :plants, only: [ :index, :show ]

  # Time series data routes
  resources :time_series_data, only: [ :index, :show ]

  # Custom route for viewing sensor time series data
  get "sensors/:id/time_series", to: "sensors#show", as: :sensor_time_series

  post "mqtt/schedule", to: "mqtt#set_schedule"
  post "mqtt/water", to: "mqtt#send_water_signal"

  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
