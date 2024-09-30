# frozen_string_literal: true

namespace :spa, path: '/' do
  resources :signup, only: [:index]
  namespace :dashboard do
    namespace :blog, path: 'community' do
      resources :posts, only: %i[index new show]
      resources :comments, only: [:index]
      get '/', to: 'posts#index'
    end
    resources :business_plan, only: [:index]
    resources :reviews, only: [:index]
    resources :comments, only: [:index]
    resources :components_builder, only: [:index]
    resources :free_subscriptions, only: [:index]
    resources :my_library, only: %i[index]
    resources :contacts, only: [:index]
    resources :optin, only: [:index]
    resources :booking, only: [:index]
    resources :polls, only: [:index]
    if Rails.application.credentials.dig(:global, :is_document_management_enabled)
      resources :documents, only: %i[index]
    end
    resource :user_management, only: [:index] do
      resources :users, only: [:index]
      resources :roles, only: %i[index edit show new] do
        get :duplicate, on: :member
      end
      get '/', to: 'users#index'
    end
  end
  get '/discover', to: 'home#index', as: :discover
  resources :home, path: '/', only: [:index]
  get '/channels/*id', to: 'channels#show', as: :channel
  resources :users, path: '/users', only: [:show]
  resources :organizations, only: %i[index]
  resources :organizations, path: '/o' do
    namespace :blog, path: 'community' do
      resources :posts, path: '/', only: %i[index show]
    end
    get 'blog/:query' => redirect(path: '/o/%{organization_id}/community/%{query}') # support existing old short urls
  end
  resources :search, only: [:index]
  resources :pricing, only: [:index]
  namespace :reports do
    resources :network_sales_reports, only: %i[index]
  end
  resources :reset_password, only: [:index]
  resources :rooms, only: [:show] do
    collection do
      get '/join/*token', to: 'rooms#join_interactive_by_token', as: :join_interactive_by_token
    end
  end
end
