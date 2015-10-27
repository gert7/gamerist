Rails.application.routes.draw do
  
  resources :rooms
  
  resources :accounts
  get '/account/unfreeze' => 'accounts#unfreeze'
  
  resources :paypals
  get "/paydata", to: "paypals#paydata"
  
  resources :payouts
  get "/payoutdata", to: "payouts#paydata"

  devise_for :users, controllers: { omniauth_callbacks: "users/oauth_callbacks", :sessions => "users/sessions" }
  
  devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy'
  end
  
  devise_for :admins, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  get Paypal::paypal_route, to: "accounts#paypal_callback"
  
  get "/account", to: "accounts#show"
  
  get "/index", to: "welcome#index"
  
  get "/static/:page", to: "static#show"
  
  get "/serverstatus", to: "serverstatus#index"
  
  root 'welcome#index'
  
  # post "/", to: "welcome#enqueue"
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  #require 'sidekiq/web'
  #mount Sidekiq::Web, :at => '/sidekiq'
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
