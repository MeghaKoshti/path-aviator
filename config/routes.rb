Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[ new create ]
  resource :email_verification, only: :create
  get "verify_email/:token", to: "email_verifications#show", as: :verify_email
  resources :learning_goals, only: %i[ new create ]
  resources :learning_paths, only: %i[ show destroy ] do
    post :regenerate, on: :member
    resource :share, only: %i[ create destroy ], module: :learning_paths
    resource :certificate, only: %i[ new create destroy ], module: :learning_paths
  end
  # Public, read-only view of a shared path, and copying it into your own account.
  get "p/:token", to: "shared_paths#show", as: :shared_path
  post "p/:token/copy", to: "shared_paths/copies#create", as: :copy_shared_path
  # Public completion certificate.
  get "c/:token", to: "certificates#show", as: :certificate
  resources :path_steps, only: [] do
    patch :toggle, on: :member
    resource :note, only: %i[ show edit update ], module: :path_steps
  end
  resource :dashboard, only: :show
  # Owner's dashboard; anyone not in ADMIN_EMAILS gets a 404.
  namespace :admin do
    root "dashboards#show"
  end
  resource :settings, only: :show
  namespace :settings do
    resource :profile, only: :update
    resource :password, only: :update
    resource :preferences, only: :update
    resource :data_export, only: %i[ create show ]
    resource :account, only: :destroy
  end
  resources :passwords, param: :token
  # One-click unsubscribe from the weekly email (signed token, no sign-in).
  resource :unsubscribe, only: %i[ show create destroy ], path: "unsubscribe/:token"

  # Policies and contact: public, linked from every footer.
  get "privacy", to: "legal_pages#privacy"
  get "terms", to: "legal_pages#terms"
  get "refunds", to: "legal_pages#refunds"
  get "contact", to: "legal_pages#contact"
  get "pricing", to: "pricing#show"

  # Curated public study plans, and the files search engines ask for.
  resources :learn_topics, path: "learn", only: %i[ index show ] do
    post :copy, on: :member
  end
  get "sitemap.xml", to: "sitemaps#show", as: :sitemap, format: false, defaults: { format: "xml" }
  get "robots.txt", to: "sitemaps#robots", as: :robots, format: false, defaults: { format: "text" }

  # Signed notifications from the payment provider (Billing::WebhookReceiver).
  post "webhooks/billing/:provider", to: "webhooks/billing#create", as: :billing_webhook

  # Billing: checkout and the customer portal live at the payment provider.
  scope "billing", module: :billing, as: :billing do
    post "checkout", to: "checkouts#create", as: :checkout
    get "return", to: "returns#show", as: :return
    post "portal", to: "portals#create", as: :portal
    post "cancel", to: "cancellations#create", as: :cancellation
    # The fake provider's "hosted" pages (development and tests only).
    unless Rails.env.production?
      get "fake/checkout/:token", to: "fake_checkouts#show", as: :fake_checkout
      post "fake/checkout/:token", to: "fake_checkouts#create"
      get "fake/portal", to: "fake_checkouts#portal", as: :fake_portal
      post "fake/portal/cancel", to: "fake_checkouts#cancel", as: :fake_portal_cancel
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "pages#home"
end
