Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    omniauth_callbacks: "users/omniauth_callbacks",
    sessions: "users/sessions"
  }
  # devise_scope :user do
  #   delete "sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
  # end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :users, only: [:show] do
    member do
      post "toggle_follow", to: "follows#toggle"
      post "remove_follower", to: "follows#remove_follower"
      get "followers", to: "users#followers"
      get "follows", to: "users#follows"
    end
  end
  resources :profiles, only: %i[edit update]
  resources :posts do
    member do
      post "like", to: "likes#like"
    end
    resources :comments do
      member do
        post "like", to: "likes#like"
        get "cancel_edit"
      end
      # collection do
      #   get "load_more"
      # end
    end
    # post "like", on: :member
    # delete "unlike", on: :member
  end
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  root "posts#index"
  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
