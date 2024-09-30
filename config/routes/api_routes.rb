# frozen_string_literal: true

namespace :api do
  namespace :v1, defaults: { format: :json } do
    namespace :organization do
      resources :users, only: %i[index show create update destroy]
      resources :channels, only: %i[index show create update destroy]
      resources :sessions, only: %i[index show create update destroy]
      resources :organizations, only: [] do
        resources :users, only: %i[index]
        resources :organization_memberships, only: %i[index show]
      end
      namespace :mind_body do
        resources :staffs, only: %i[show update]
      end
      namespace :partner do
        resources :subscriptions, only: %i[index]
      end
    end
    namespace :auth do
      resources :organizations, only: %i[create]
      resource :guests, only: %i[create update]
      resources :signup_tokens, only: %i[show]
      resources :users, only: %i[create] do
        collection do
          delete :destroy
        end
      end
      resources :registrations, only: %i[create]
      resources :passwords, only: %i[create]
      resources :user_tokens, only: [] do
        get :show, on: :collection
      end
      resources :room_member_guest_tokens, only: %i[create]
      resources :usage_tokens, only: [:create]
      resources :websocket_tokens, only: [:create]
    end

    namespace :system do
      resources :logs, only: %i[create]
      resources :cable, only: %i[create]
      resources :webpush, only: %i[create]
    end
    namespace :user do
      namespace :booking do
        resources :bookings, except: %i[update]
        resources :booking_slots do
          member do
            get :calculate_price
            get :bookings
          end
        end
        resources :booking_categories, only: %i[index]
      end
      namespace :feed do
        resources :sessions, only: %i[index]
        resources :videos, only: %i[index]
        resources :recordings, only: %i[index]
        resources :documents, only: %i[index]
      end
      namespace :poll do
        resources :poll_templates, except: %i[new edit] do
          resources :polls, except: %i[new edit] do
            post :vote, as: :member
          end
        end
      end
      namespace :customer do
        resources :subscriptions, only: %i[index]
        resources :free_subscriptions, only: %i[index]
      end
      namespace :partner do
        resources :plans, only: %i[index show create update destroy]
        resources :subscriptions, only: %i[index show update destroy]
      end
      namespace :webrtcservice do
        namespace :chat do
          resource :access_tokens, only: %i[create]
        end
      end
      namespace :access_management do
        resources :groups, only: %i[index show create update destroy]
        resources :credentials, only: %i[index]
        resources :channels, only: %i[index]
        resources :organizations, only: [] do
          resources :organization_memberships, only: %i[index show create update destroy] do
            post :import_from_csv, on: :collection
          end
          resources :group_members, only: %i[update]
        end
      end
      namespace :mailing do
        resources :emails, only: %i[create] do
          collection do
            post :preview
          end
        end
        resources :templates, only: %i[index]
      end
      namespace :payouts do
        resources :countries, only: %i[index]
        resources :states, only: %i[index]
        resources :merchant_categories, only: %i[index]
        resources :payout_methods, only: %i[index show create update destroy] do
          resources :connect_accounts, only: %i[create update]
          resources :connect_bank_accounts, only: %i[create update]
        end
      end
      resources :users, only: %i[show update destroy]
      resources :sessions, only: %i[index show new create update destroy] do
        get :nearest_session, on: :collection
        post :confirm_purchase, on: :member
        resource :session_duration, path: '/durations', only: %i[show create destroy]
      end
      namespace :reports do
        resources :network_sales_reports, only: %i[index]
        resources :channels, only: %i[index]
        resources :organizations, only: %i[index]
      end
      resources :rooms, only: %i[show update] do
        resources :room_members, only: %i[index] do
          collection do
            post :mute_all
            post :unmute_all
            post :start_all_videos
            post :stop_all_videos
            post :enable_all_backstage
            post :disable_all_backstage
            post :pin
            post :pin_only
            post :unpin
            post :unpin_all
          end
          member do
            post :allow_control
            post :disable_control
            post :mute
            post :unmute
            post :start_video
            post :stop_video
            post :ban_kick
            post :unban
            post :enable_backstage
            post :disable_backstage
          end
        end
        get :room_existence, on: :member
        post :join_interactive_by_token, on: :collection
      end
      resources :channels, only: %i[index] do
        resources :sessions, only: %i[index new create]
      end
      resources :videos, only: %i[index]
      resources :recordings, only: %i[index show]
      resources :notifications, only: %i[index show] do
        collection do
          post :mark_as_read
          post :mark_as_unread
          delete :destroy
        end
      end
      resources :user_search, only: %i[index]
      resources :payment_methods, only: %i[index]
      resources :channel_free_subscriptions, only: %i[index show]
      resources :channel_subscriptions, only: %i[index show create] do
        post :check_recipient_email, on: :member
      end
      resources :free_subscriptions, only: %i[index new create]
      resources :service_subscriptions, only: %i[index show create update destroy] do
        get :current, on: :collection
        post :pay, on: :member
        post :apply_coupon, on: :collection
      end
      resources :payment_transactions, only: %i[index]
      resources :organizations, only: %i[index update show] do
        post :set_current, on: :member
      end
      resources :organization_memberships, only: %i[index show update]
      resources :statistics, only: %i[index]
      resources :system_themes, only: %i[index show update]
      resources :home_entity_params, only: %i[] do
        collection do
          post :hide_on_home
          post :set_weight
        end
      end
      resources :contacts, only: %i[index create update] do
        collection do
          post :import_from_csv
          post :export_to_csv
          delete :destroy
        end
      end
      namespace :storage do
        resources :records, only: %i[index]
      end
      resources :studios, only: %i[index show create update destroy] do
        resources :studio_rooms, only: %i[index show create update destroy]
      end
      resources :studio_rooms, only: %i[index show create update destroy]
      resources :ffmpegservice_accounts, only: %i[index new create show update destroy] do
        get :get_status, on: :member
      end
      resources :stream_previews, only: %i[index show create destroy]
      resources :follows, only: %i[index show create destroy] do
        collection do
          get '/:followable_type/:followable_id' => :show, as: :show
          post '/:followable_type/:followable_id' => :create, as: :create
          delete '/:followable_type/:followable_id' => :destroy, as: :destroy
        end
      end
      resources :conversations, only: %i[index show] do
        collection do
          delete :destroy
          post :mark_as_read
          post :mark_as_unread
        end
      end
      resources :receipts, only: %i[show update]
      resources :activities, only: %i[index show] do
        collection do
          delete :destroy
          match :destroy_all, via: %i[post get]
        end
      end
      namespace :shop do
        resources :lists, only: %i[index show create update destroy]
        resources :products, only: %i[index show create update destroy] do
          collection do
            post :search_by_upc
          end
        end
      end
      resource :confirmations, only: %i[create]
      resource :zoom_accounts, only: %i[show]
      resources :interactive_access_tokens, only: %i[index show create update destroy]
      resources :mentions, only: %i[index]
      resources :channel_invited_presenterships, only: %i[index show update]
      resources :session_invited_immersive_participantships, except: %i[new edit]
      resources :session_invited_livestream_participantships, except: %i[new edit]
      resources :reviews, only: %i[index show create update destroy] do
        collection do
          get '/:reviewable_type/:reviewable_id' => :index, as: :index
        end
      end
      resources :comments, only: %i[index show create update destroy] do
        collection do
          get '/:commentable_type/:commentable_id' => :index, as: :index
        end
      end
      namespace :active_storage do
        resources :direct_uploads, only: %i[create]
        resource :disk, only: %i[show update]
      end
      if Rails.application.credentials.dig(:global, :is_document_management_enabled)
        resources :documents, only: %i[index show create update destroy] do
          post :buy, on: :member
        end
      end
      if Rails.application.credentials.dig(:global, :instant_messaging, :enabled)
        namespace :im do
          if Rails.application.credentials.dig(:global, :instant_messaging, :conversations, :channels, :enabled)
            resources :channel_conversations, only: %i[index]
          end
          resources :sessions, only: %i[] do
            if Rails.application.credentials.dig(:global, :instant_messaging, :conversations, :sessions, :enabled)
              resource :session_conversations, only: %i[show], path: 'conversation'
            end
          end
          resources :conversations, only: %i[] do
            resources :messages, only: %i[index create update destroy]
          end
        end
      end
      namespace :page_builder do
        resources :home_banners, only: %i[show create destroy]
        resources :system_templates, only: %i[index show create destroy]
        resources :model_templates, only: %i[index show create destroy]
      end
      namespace :marketing_tools do
        resources :opt_in_modals, only: %i[index show create update destroy]
      end
      resources :signup_tokens, only: %i[create]
      resources :feature_usages, only: %i[index]
      resources :feature_history_usages, only: %i[index]
      resources :abstract_session_cancel_reasons, only: %i[index]
    end
    namespace :guest do
      resources :rooms, only: [] do
        collection do
          get :show
          get :room_existence
          post :join_interactive_by_token
        end
      end
    end
    namespace :sandbox do
      resources :system_themes, only: %i[index]
    end
    namespace :public do
      resources :ad_clicks, only: :create
      namespace :poll do
        resources :polls, only: :show
      end
      namespace :booking do
        resources :booking_slots, only: :index
      end
      resources :ban_reasons, only: %i[index show]
      resources :support_messages, only: [] do
        post :contact_us, on: :collection
      end
      resources :organizations, only: %i[index show] do
        get :default_location, on: :member
        resources :organization_memberships, only: %i[index]
        resources :organization_members, only: %i[index]
      end
      resources :organization_memberships, only: %i[index]
      resources :channels, only: %i[index show] do
        resources :channel_subscription_plans, only: %i[index show]
        resources :channel_members, only: %i[index]
        resources :channel_reviews, only: %i[index]
      end
      resources :recordings, only: %i[index show] do
        resources :embeds, only: %i[index]
      end
      resources :videos, only: %i[index show] do
        resources :embeds, only: %i[index]
      end
      resources :users, only: %i[show create update destroy] do
        collection do
          get :fetch_avatar
        end
        member do
          get :creator_info
        end
      end
      resources :user_accounts, only: %i[show]
      resources :sessions, only: %i[index show] do
        resources :embeds, only: %i[index]
      end
      resources :plan_packages, only: %i[index show]
      resources :service_plans, only: %i[show]
      resources :share, only: %i[index] do
        post :email, on: :collection
      end
      resources :search, only: %i[index]
      namespace :search do
        namespace :blog do
          resources :posts, only: %i[index]
        end
        resources :users, only: %i[index]
        resources :channels, only: %i[index]
        resources :sessions, only: %i[index]
        resources :videos, only: %i[index]
        resources :recordings, only: %i[index]
      end
      namespace :calendar do
        resources :sessions, only: %i[index]
        resources :videos, only: %i[index]
      end
      namespace :home do
        resources :organizations, only: %i[index]
      end
      namespace :page_builder do
        resources :ad_banners, only: %i[index]
        resources :system_templates, only: %i[show]
        resources :model_templates, only: %i[show]
      end
      namespace :marketing_tools do
        resources :opt_in_modals, only: %i[index] do
          put :track_view, on: :member
        end
        resources :opt_in_modal_submits, only: %i[create]
      end
      resources :organizations do
        namespace :mind_body do
          resources :class_schedules, only: %i[index]
          resources :sites, only: %i[create]
        end
      end
      resources :followers, only: [] do
        collection do
          get '/:followable_type/:followable_id' => :index, as: :index
        end
      end
      resources :follows, only: [] do
        collection do
          get '/:follower_type/:follower_id' => :index, as: :index
        end
      end
      resources :interactive_access_tokens, only: %i[show]
      namespace :shop do
        resources :products, only: %i[index show]
        resources :lists, only: %i[index show]
      end
      resources :reviews, only: %i[index] do
        collection do
          get '/:reviewable_type/:reviewable_id' => :index, as: :index
        end
      end
      resources :comments, only: %i[index] do
        collection do
          get '/:commentable_type/:commentable_id' => :index, as: :index
        end
      end
      if Rails.application.credentials.dig(:global, :is_document_management_enabled)
        resources :documents, only: %i[index show]
      end
    end
    namespace :pages do
      resource :header, only: %i[show], controller: :header
      resource :footer, only: %i[show], controller: :footer
    end
    namespace :blog do
      resources :posts, only: %i[index show new create update destroy] do
        post :vote, on: :member
        resources :comments, only: %i[index create]
        resources :images, only: %i[index], on: :member
      end
      resources :comments, only: %i[index show create update destroy]
      resources :link_previews, only: %i[index create show] do
        member do
          get :parse
        end
      end
      resources :images, only: %i[index create show update destroy]
    end
    namespace :webhook do
      namespace :partner do
        resources :subscriptions, only: %i[create update destroy]
      end
    end
  end
  namespace :v1s1, defaults: { format: :json }, path: 'v1.1' do
    namespace :user do
      resources :rooms, only: %i[show update]
    end
  end
end
