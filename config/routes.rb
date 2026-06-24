Rails.application.routes.draw do
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "auth/login", to: "auth#login"
      post "auth/refresh", to: "auth#refresh"
      delete "auth/logout", to: "auth#logout"

      get "me", to: "users#me"

      post "password/forgot", to: "passwords#create"
      put  "password/reset",  to: "passwords#update"

      resources :companies
      resources :bulls

      resources :cows do
        resources :events, only: [ :index, :create ], controller: "events"
      end

      resources :events, only: [ :index ]

      resources :breeds, only: [ :index ]

      scope "dashboard", controller: "dashboard" do
        get "reproductive-summary", action: :reproductive_summary
        get "phase-summary", action: :phase_summary
        get "alerts", action: :alerts
        get "reproductive-indicators", action: :reproductive_indicators
        get "event-counts", action: :event_counts
      end
    end
  end
end
