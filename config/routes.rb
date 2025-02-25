Rails.application.routes.draw do
  resources :bookings do
    collection do
      get :pending
    end
    member do
      post :cancel
      get :driver_location
    end
  end
  resources :rides do
    member do
      post :start
      post :finish
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
    get "/dashboard", to: "dashboard#show", as: :dashboard
  end

  post "driver/update_location", to: "driver_profiles#update_location"

  get "dashboard/rides", to: "dashboard#rides"

  resources :users do
    member do
      patch :restore
      delete :permanent_delete
    end
  end
end
