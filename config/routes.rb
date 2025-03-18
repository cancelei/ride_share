Rails.application.routes.draw do
  resources :rides do
    member do
      post :cancel
      post :start
      post :finish
      post :verify_security_code
      patch :mark_as_paid
      patch :accept
      patch :complete
      get :driver_location
    end
  end

  resources :passenger_profiles
  resources :driver_profiles do
    resources :vehicles do
      member do
        post :select
      end
    end
  end

  get "places/autocomplete"

  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Landing page route
  root "pages#landing", as: :root

  # Authenticated user routes
  authenticated :user do
    get "/dashboard", to: "dashboard#index", as: :dashboard
    get "/dashboard/user_rides", to: "dashboard#user_rides", as: :user_rides
  end

  post "driver/update_location", to: "driver_profiles#update_location"

  resources :users do
    member do
      patch :restore
      delete :permanent_delete
    end
  end

  # Mount Letter Opener Web interface in development
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Email testing routes (development only)
  if Rails.env.development?
    get "test_email/:email_type", to: "rides#test_emails", as: :test_email
  end
end
