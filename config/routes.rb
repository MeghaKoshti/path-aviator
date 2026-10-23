Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "pages#home"

  # Placeholder — implemented in feature stories (see PlaceholdersController).
  get "dashboard", to: "placeholders#dashboard", as: :dashboard
  get "registration/new", to: "placeholders#new_registration", as: :new_registration
  get "learning_goals/new", to: "placeholders#new_learning_goal", as: :new_learning_goal
  get "settings", to: "placeholders#settings", as: :settings
end
