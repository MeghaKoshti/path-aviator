Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[ new create ]
  resources :learning_goals, only: %i[ new create ]
  resources :learning_paths, only: %i[ show destroy ] do
    post :regenerate, on: :member
  end
  resources :path_steps, only: [] do
    patch :toggle, on: :member
  end
  resource :dashboard, only: :show
  resource :settings, only: :show
  namespace :settings do
    resource :profile, only: :update
    resource :password, only: :update
    resource :account, only: :destroy
  end
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "pages#home"
end
