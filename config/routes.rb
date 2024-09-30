# frozen_string_literal: true

Rails.application.routes.default_url_options[:host] = ENV['HOST']
Rails.application.routes.default_url_options[:protocol] = ENV['PROTOCOL'] || 'http://'
Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/docs'
  mount Rswag::Api::Engine => '/docs'

  mount ActionCable.server => '/cable'

  draw(:webhook_routes)

  draw(:api_routes)

  authenticate :admin do
    mount Sidekiq::Web => '/jobs/sidekiq'
  end

  mount Kss::Engine => '/kss' if Rails.env.development? || Rails.env.qa?
  get '/larryfournillier-4e88b23e-e7a9-4f68-957c-f5abd20ff120' => redirect('/larryfournillier') if Rails.env.production?
  if Rails.env.test? || Rails.env.qa?
    get '/rails/mailers' => 'rails/mailers#index'
    get '/rails/mailers/*path' => 'rails/mailers#preview'
  end

  devise_for :admins, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # devise_for route must be placed before the mounted engine
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',

    confirmations: 'users/confirmations',
    invitations: 'users/invitations',
    passwords: 'users/passwords',
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  devise_scope :user do
    get 'users/auth/:provider/setup' => 'users/omniauth_callbacks#setup'
    match 'users/auth/:provider/verify' => 'users/omniauth_callbacks#verify', via: %i[get post]
  end

  get '/go/:service', to: 'system#go'

  # "customize the layout of your error handling using controllers and views"
  # NOTE: I'm following official Rails documentation/recommendation here
  match '/400', to: 'errors#not_found', via: %i[get post patch put delete] # We should handle all routes, otherwise we get white screen
  match '/404', to: 'errors#not_found', via: %i[get post patch put delete] # We should handle all routes, otherwise we get white screen
  match '/406', to: 'errors#not_found', via: %i[get post patch put delete]
  match '/422', to: 'errors#unprocessable_entity', via: %i[get post patch put delete]
  match '/500', to: 'errors#server_error', via: %i[get post patch put delete]

  match '/readme', to: 'errors#not_found', via: %i[get post patch put delete]
  match '/install', to: 'errors#not_found', via: %i[get post patch put delete]
  match '/xmlrpc', to: 'errors#not_found', via: %i[get post patch put delete]
  match '/feed', to: 'errors#not_found', via: %i[get post patch put delete]
  match '/atom', to: 'errors#not_found', via: %i[get post patch put delete]
  match '/rss', to: 'errors#not_found', via: %i[get post patch put delete]
  match '/index', to: 'errors#not_found', via: %i[get post patch put delete]
  match '/browserconfig', to: 'errors#not_found', via: %i[get post patch put delete]

  get '/unsubscribe/:token' => 'unsubscribes#preview', as: :preview_unsubscribe
  post '/unsubscribe' => 'unsubscribes#confirm'

  post '/refer_friends' => 'shares#refer_friends'
  match '/paypal/confirm_purchase' => 'paypal#confirm_purchase', via: %i[get post]
  if defined?(TimecopConsole)
    mount TimecopConsole::Engine => '/timecop_console'
  end

  namespace :paypal do
    resources :webhooks, only: [:create]
  end

  namespace :stripe do
    resources :plans, only: [] do
      resources :subscriptions, only: %i[create new]
    end
    resources :subscriptions, only: [] do
      member do
        get :preview_plans
        get :preview_purchase
        post :check_recipient_email
        delete :unsubscribe
      end
    end
    resources :service_subscriptions, only: %i[update destroy]
    resources :webhooks, only: [] do
      collection do
        post :connect
        post :general
      end
    end
  end

  resource :session_invited_immersive_co_presenterships do
    collection do
      post :forcefully_close
    end
  end

  resources :session_invited_immersive_participantships do
    collection do
      post :forcefully_close
    end
  end

  resources :organizations, except: %i[index show destroy] do
    member do
      post :leave
      post :set_current
      match :accept_invitation, via: %i[post get]
      post :reject_invitation
    end
  end

  resources :session_invited_livestream_participantships do
    collection do
      post :forcefully_close
    end
  end

  resources :channel_invited_participantships do
    collection do
      post :forcefully_close
    end
  end

  resources :channels, only: %i[new create edit update] do
    member do
      post :request_session
      post :archive
      post :list
      post :share
      post :submit_for_review
      post :unlist
      put :notify_me
      put :you_may_also_like_visibility
      match :accept_invitation, via: %i[post get]
      post :reject_invitation
      get :streams
      get :replays
      get :recordings
      get :reviews
      get :edit_creators
      post :save_creators
      get :sessions_list
      get :replays_list
      get :recordings_list
      get :full_calendar_events
    end
    resources :sessions do
      member do
        get :modal_review
        get :ical

        match :confirm_purchase, via: %i[get post]
        match :paypal_purchase, via: %i[get post]
        match :confirm_paypal_purchase, via: %i[post get]

        post :request_another_time

        post :publish
        post :share
        post :toggle_in_waiting_list
        get :clone
        post :pre_time_overlap
      end
      collection do
        post :pre_time_overlap
      end
    end
  end

  get '/sessions/new' => 'sessions#new', as: :sessions_new

  resources :sessions, only: [] do
    collection do
      get :more_from_presenter
      post :apply_coupon
    end
    member do
      get :get_stream_url
      get :get_join_button
      post :toggle_remind_me
    end
  end

  resources :recordings, only: %i[destroy update] do
    member do
      post :get_video
      get :preview_purchase
      match :confirm_purchase, via: %i[get post]
      match :paypal_purchase, via: %i[get post]
      match :confirm_paypal_purchase, via: %i[post get]
    end
  end

  resources :shares, only: [] do
    collection do
      post :email
    end
  end

  resources :wishlist_items, only: [] do
    collection do
      post :toggle
    end
  end

  resources :products, only: :none do
    post :fetch, on: :collection
    get :fetch_products, on: :collection
    get :search_by_upc, on: :collection
  end

  resources :lists, except: %i[new show] do
    resources :products, except: %i[new show]
  end

  scope module: 'dashboard', path: 'dashboard', as: 'dashboard' do
    resources :statistics, only: :index
    resources :lists, except: [:show] do
      resources :products, except: [:show] do
        post :search_by_url, on: :collection
        post :search_by_upc, on: :collection
      end
    end
    resources :subscriptions, except: [:show]
    resources :money, only: [] do
      collection do
        get :earnings
        get :payouts
        get :products_earnings
        get :purchases
        get :my_subscriptions
      end
    end
    resources :studios, only: :index
    resources :video_sources, only: :index
    resources :history, only: :index
    resources :replays, only: %i[update destroy] do
      member do
        post :publish_toggle
        post :save_image
      end
      collection do
        post :group_publish
        post :group_destroy
        post :group_move
      end
    end
    resources :uploads, only: %i[update destroy] do
      member do
        post :publish
        post :publish_toggle
        post :save_image
      end
      collection do
        post :group_publish
        post :group_destroy
        post :group_move
      end
    end
    resources :channels, only: [] do
      member do
        resources :uploads, only: %i[create index]
        resources :replays, only: [:index]
        get :sessions
      end
    end
    resources :mailing, only: [:index] do
      collection do
        post :send_time_to_service
        post :email_preview
        post :send_email
      end
    end
  end

  resource :dashboard, only: :show do
    collection do
      get :sessions_presents
      get :sessions_co_presents
      get :sessions_participates
      get :wishlist
      # get :edit_contacts
      get :edit_referral
      get :followers
      get :following
      get :company
      get :uploads
      get :replays
      get :video_on_demand_link
    end
  end

  resources :payment_methods, only: %i[create update destroy]
  namespace :payouts do
    resources :connect_accounts, only: %i[create update]
    resources :connect_bank_accounts, only: %i[create update]
    resources :payout_methods, only: %i[index create edit update destroy]
  end

  resources :lobbies, only: [:show] do
    member do
      get :io, to: 'lobbies#vidyoio', as: :vidyoio
      # REMOVEME AFTER FIX LOBBIES PAGE
      # post :auth_callback
      # post :after_join
      post :start_streaming
      post :stop_streaming
      post :be_right_back_on
      post :be_right_back_off
      post :start_or_resume_record
      post :pause_record
      post :allow_control
      post :mute
      post :unmute
      post :mute_all
      post :unmute_all
      post :start_video
      post :stop_video
      post :start_all_videos
      post :start_fb_stream
      post :switch_autostart
      post :switch_chat
      post :stop_all_videos
      post :stop_lecture_mode
      get :start_rtmp_stream # start_ffmpegservice_stream
      post :enable_backstage
      post :disable_backstage
      post :enable_all_backstage
      post :disable_all_backstage
      post :ban_kick
      post :disable_control
      post :ask
      post :silence_all
      post :answer
      post :has_youtube_access
      get :room_existence
      get :add_member
      get :refresh_manager_panel
      get :dropbox_media_url
      get :get_dropbox_media
      post :change_duration
      post :start_immerss_stream
      post :start_youtube_stream
      post :stop_stream
      post :stream_alive
      post :enable_list
      post :disable_list
    end
  end

  resources :livestreams, only: [:show] do
    member do
      post :auth_callback
      post :start_immerss_stream
      post :start_youtube_stream
      post :stop_stream
      post :stream_alive
      post :start_fb_stream
      get :room_existence
      get :add_member
    end
  end

  get '/profiles/preview_phone_number_verification_modal' => 'profiles#preview_phone_number_verification_modal',
      as: :preview_phone_number_verification_modal
  post '/profiles/verify_phone_number' => 'profiles#verify_phone_number', as: :verify_phone_number

  get '/sessions/:id/participants' => 'sessions#participants', as: :participants_session
  post '/sessions/:id/get_access_by_code' => 'sessions#get_access_by_code', as: :get_access_by_code

  post '/send-email-confirmation-from-preview-purchase' => 'sessions#send_email_confirmation_from_preview_purchase'

  get '/sessions/:id/preview_accept_invitation' => 'sessions#preview_accept_invitation',
      as: :sessions_preview_accept_invitation_modal
  get '/sessions/:id/preview_cancel_modal' => 'sessions#preview_cancel_modal',
      as: :sessions_preview_cancel_modal

  get '/sessions/:id/preview_clone_modal' => 'sessions#preview_clone_modal',
      as: :sessions_preview_clone_modal

  get '/sessions/:id/preview_live_opt_out_modal' => 'sessions#preview_live_opt_out_modal',
      as: :sessions_preview_live_opt_out_modal
  get '/sessions/:id/preview_vod_opt_out_modal' => 'sessions#preview_vod_opt_out_modal',
      as: :sessions_preview_vod_opt_out_modal

  resources :sessions, only: [:index] do
    member do
      get :unchain
      post :submit
    end
  end

  post 'sessions/:id/cancel' => 'sessions#cancel', as: 'cancel_session'

  # because for following 3 lines in any particular case it is only one type of access per user - immersive OR livestream(mutually exclusive)
  post 'sessions/:id/live_opt_out_without_money_refund' => 'sessions#live_opt_out_without_money_refund',
       as: 'live_opt_out_without_money_refund_session'
  post 'sessions/:id/live_opt_out_and_get_money_refund' => 'sessions#live_opt_out_and_get_money_refund',
       as: 'live_opt_out_and_get_money_refund_session'

  post 'sessions/:id/vod_opt_out_without_money_refund' => 'sessions#vod_opt_out_without_money_refund',
       as: 'vod_opt_out_without_money_refund_session'
  post 'sessions/:id/vod_opt_out_and_get_money_refund' => 'sessions#vod_opt_out_and_get_money_refund',
       as: 'vod_opt_out_and_get_money_refund_session'

  match 'sessions/:id/accept_invitation' => 'sessions#accept_invitation', as: 'accept_invitation_session',
        via: %i[post get]
  # NOTE: get method is needed because there is important redirect after submitting missing profile info(ProfilesController)
  post 'sessions/:id/reject_invitation' => 'sessions#reject_invitation', as: 'reject_invitation_session'

  get 'sessions/:id/modal_live_participants_portal' => 'sessions#modal_live_participants_portal',
      as: :modal_session_live_participants_portal
  get 'sessions/:id/modal_live_participants_video' => 'sessions#modal_live_participants_video',
      as: :modal_session_live_participants_video

  post 'sessions/:id/invited_users_portal' => 'sessions#invited_users_portal', as: :session_invited_users_portal

  post 'sessions/:id/instant_invite_user_from_video' => 'sessions#instant_invite_user_from_video',
       as: :session_instant_invite_user_from_video
  post 'sessions/:id/instant_remove_invited_user_from_video' => 'sessions#instant_remove_invited_user_from_video',
       as: :session_instant_remove_invited_user_from_video

  resource :profile, only: %i[update destroy] do
    get 'edit_general'
    get 'edit_notifications'
    get 'edit_preferences'
    get 'edit_application'
    get 'edit_billing'
    get 'edit_public'
    get 'stream_options'
    get 'download_client'
    get 'donations'
    put 'update_donations'
    put 'update_general'
    put 'update_settings'
    put 'update_application'
    put 'update_public'
    post 'detach_credit_card'
    post :save_cover, defaults: { format: 'json' }
    post :save_logo, defaults: { format: 'json' }
  end

  put 'time_format' => 'profiles#time_format'
  post 'profiles/:provider/disconnect_social_account' => 'profiles#disconnect_social_account',
       as: :disconnect_social_account

  resources :replenishments, only: %i[new create]

  resources :complete_presenter, only: :index, path: 'complete-creator' do
    post :save, on: :collection
  end

  post 'lets_talk' => 'become_presenter_steps#lets_talk', as: :lets_talk
  # TODO: cleanup
  resources :become_presenter_steps, only: [], path: 'create-live-network' do
    collection do
      post :save_user, defaults: { format: 'json' }
      post :log_step2, defaults: { format: 'json' }
      post :log_step3, defaults: { format: 'json' }
      post :continue

      post :save_company, defaults: { format: 'json' }

      post :save_channel, defaults: { format: 'json' }
      patch :save_channel, defaults: { format: 'json' }

      post :save_channel_cover, defaults: { format: 'json' }
      post :save_channel_gallery_image, defaults: { format: 'json' }
      post :save_channel_link, defaults: { format: 'json' }
      delete :remove_channel_image, defaults: { format: 'json' }
      delete :remove_channel_link, defaults: { format: 'json' }

      post :save_user_account, defaults: { format: 'json' }

      post :search_presenter, defaults: { format: 'json' }
      post :add_presenter, defaults: { format: 'json' }
      delete :remove_presenter, defaults: { format: 'json' }
    end
  end

  resources :presenters, only: %i[index show]
  resources :notifications, only: %i[index destroy] do
    delete :destroy_all,      on: :collection
    delete :destroy_read,     on: :collection
    delete :destroy_selected, on: :collection
    post :bulk_read,          on: :collection
    post :mark_all_as_read,   on: :collection

    post :mark_as_read,       on: :member
    post :mark_as_unread,     on: :member
  end

  resources :users, only: [] do
    member do
      post :share
      get :home
    end
    collection do
      post :video_on_profile
    end
  end

  get 'pending_refunds/:id/get_money' => 'pending_refunds#get_money', as: :pending_refund_get_money
  get 'pending_refunds/:id/get_system_credit' => 'pending_refunds#get_system_credit',
      as: :pending_refund_get_system_credit

  %i[session_participations session_co_presenterships livestreamers].each do |resource|
    resources resource do
      member do
        get :accept_changed_start_at
        get :decline_changed_start_at
      end
    end
  end

  get 'server_time.json' => 'system#server_time', as: 'server_time'

  match '/reviews/:model_id/rate' => 'reviews#rate', via: %i[post put], as: :review_rate
  match '/reviews/:model_id/comment' => 'reviews#comment', via: %i[post put], as: :review_comment

  controller :paypal_donations do
    match 'paypal_donations/info', via: [:get], as: :donations_amount_paypal_donations
    match 'paypal_donations/toggle_visibility', via: [:post], as: :toggle_visibility_paypal_donations

    match 'success_ipn_callback', via: [:post]
    match 'failure_ipn_callback', via: [:post]
  end

  controller :pages do
    get 'robots.txt' => :robots
    get 'sitemap.xml' => :sitemap

    [
      ContentPages::ABOUT,
      (ContentPages::HELP_CENTER if Rails.application.credentials.global[:pages][:help]),
      (ContentPages::TERMS_CONDITIONS if Rails.application.credentials.global[:pages][:terms_and_privacy]), # do not rename/change path because some social apps have already that URL in settings
      (ContentPages::PRIVACY_POLICY if Rails.application.credentials.global[:pages][:terms_and_privacy]), # do not rename/change path because some social apps have already that URL in settings
      ContentPages::REFUND_AND_CANCELLATION_POLICY, # do not rename/change path because some social apps have already that URL in settings
      ContentPages::OLD_BROWSER,
      ContentPages::HELP_WIDGET
    ].compact.each do |title|
      get "pages/#{title.parameterize(separator: '-')}" => :show, id: title.parameterize(separator: '_')
    end
  end

  if Rails.application.credentials.global[:pages][:help]
    get '/pages/help', to: redirect("pages/#{ContentPages::HELP_CENTER.parameterize(separator: '-')}")
  end

  resources :messages

  get '/conversations/:id/preview_modal' => 'conversations#preview_modal', as: :preview_modal_conversation

  resources :contacts, only: [] do
    collection do
      post :toggle_contact
    end
  end
  resource :channel_links, only: :create

  resource :remote_validations, only: [] do
    get :user_email
    get :channel_title
    get :organization_name
    get :social_link
    post :user_slug
  end

  resources :chat_members, only: [:create]
  resources :widgets, only: [:index] do
    collection do
      get :live
    end
    member do
      get '/:class/shop' => :shop, as: :shop
      get '/:class/player' => :player, as: :player
      get '/:class/additions' => :additions, as: :additions
      get '/:class/playlist' => :playlist, as: :playlist
      get '/:class/chat' => :chat, as: :chat
      get '/:class/embedv2' => :embedv2, as: :embedv2
    end
  end

  resources :ffmpegservice_accounts, only: [] do
    collection do
      post :find_or_assign
      post :find
      post '/:organization_id/:service_type/' => :create, as: :create
    end
    member do
      post :start_stream
      post :stop_stream
    end
  end

  resources :polls, only: [:create] do
    collection do
      post :vote
      get :fetch_polls
    end
  end

  # NOTE: if you ever need to update it  take a look at config/initializers/rack-attack.rb first
  post '/shares/increment'
  resource :home, only: [], path: '/', controller: 'home' do
    # get :discover
    get :business
    get :landing # FIXME: MOVE in to Landing controller
    get :support
    get :zoom_docs
  end
  get 'go-live' => 'home#business', as: :go_live

  if Rails.application.credentials.global[:show_landing]
    root to: 'home#landing'
  else
    root to: 'spa/home#index'
  end
  unless Rails.env.production?
    resources :sandbox, only: [:index]
    resources :ome, only: [:index]
    resources :spa_app, only: [:index]
    match '/history', to: 'spa_app#index', via: [:get], as: :spa_history
  end

  draw(:spa_routes)

  resources :dropbox, only: [:index] do
    collection do
      get :authorize
      post :disconnect
      get '*id', action: :show, format: false
    end
  end

  # get '/wizard', to: 'wizard#profile', as: :wizard
  # scope path: 'wizard', as: 'wizard' do
  #   get :profile, to: 'wizard#profile'
  #   post :profile, to: 'wizard#save_profile'
  #   get :channel, to: 'wizard#channel'
  #   post :channel, to: 'wizard#save_channel'
  #   get :settings, to: 'wizard#settings'
  #   post :save_settings, to: 'wizard#save_settings'
  #   post :search_creator, to: 'wizard#search_creator'
  #   post :add_creator, to: 'wizard#add_creator'
  #   delete :remove_creator, to: 'wizard#remove_creator'
  #   get :submit, to: 'wizard#submit'
  #   post :submit_for_approval, to: 'wizard#submit_for_approval'
  # end

  namespace :wizard_v2, path: 'wizard' do
    get '/' => redirect('/landing')
    resource :profile, only: [:update], controller: :profile
    resource :business, only: %i[show update], controller: :business
    resource :channel, only: %i[show update], controller: :channel
    resource :summary, only: [:show], controller: :summary do
      post :submit_for_approval
    end
  end

  match '/sessions/:session_slug/preview_purchase', to: 'sessions#preview_purchase',
                                                    as: :preview_purchase_channel_session, via: :get, constraints: { session_slug: /.*/ }

  # TODO: delete?
  # resources :rooms, only: [] do
  #   member do
  #     match :toggle_notify_me, via: [:get, :post]
  #     get :show, defaults: {format: :json}
  #   end
  # end

  scope module: 'api', path: 'api_portal', as: 'api' do
    scope path: 'home' do
      resources :videos, only: [] do
        collection do
          get '/' => :for_home
        end
      end
    end

    scope module: 'invitations', path: 'invitations', as: 'invitations' do
      resources :channels, only: [:index] do
        member do
          post :accept
          post :reject
        end
      end
    end
    scope module: 'system', path: 'system', as: 'system' do
      resources :firebase, only: [:create]
      resources :storage, only: [] do
        collection do
          get '/:recording_id/qencode_recording_url' => :qencode_recording_url, as: :qencode_recording_url
        end
      end

      resources :resque, only: [] do
        collection do
          post :create_reminders
          post :disable_reminders
        end
      end
      resources :mailers, only: [] do
        collection do
          post :recording_ready
          post :video_ready
          post :video_uploaded
          post :you_as_co_presenter_accepted_session_invitation
          post :you_as_participant_accepted_session_invitation
          post :user_rejected_your_session_invitation
          post :user_accepted_your_session_invitation
        end
      end
      resources :sessions, only: [] do
        member do
          post :update_pg_search_document
        end
      end
      resources :videos, only: [] do
        member do
          post :update_pg_search_document
        end
      end
      resources :recordings, only: [] do
        member do
          post :update_pg_search_document
        end
      end
      resources :rooms, only: [] do
        member do
          post :status_changed
        end
      end
      resources :ffmpegservice_accounts, only: [] do
        member do
          post :update_stream_status
        end
      end
    end

    resources :channels, only: [] do
      resources :sessions, only: %i[index new create update]
      resources :recordings, only: [:index]
      resources :videos, only: [:index]
    end
    resources :sessions, only: [] do
      member do
        match :confirm_purchase, via: %i[get post]
        match :paypal_purchase, via: %i[get post]
        post :invite_participant
        get :invited_participants
        post :remove_participant
      end
    end
    resources :recordings, only: [] do
      member do
        match :confirm_purchase, via: %i[get post]
      end
    end
    resources :products, only: [] do
      get :search_by_upc, on: :collection
    end
    resources :users, only: [:show] do
      member do
        post :toggle_follow
      end
      collection do
        resources :videos, only: [] do
          collection do
            get '/' => :for_user
          end
        end
      end
    end

    resources :chats, only: [:show]
    resources :rooms, only: [] do
      resources :chats, only: [] do
        collection do
          post :switch
        end
      end
    end
  end

  class NotFoundOrTitleParameterized
    def self.matches?(request)
      # NOTE: there are 2 kind  of requests:
      # /apple-touch-icon-precomposed
      # and
      # /apple-touch-icon
      # ignore both in this method
      %w[s/ switch_user apple-touch-icon users/password favicon pages admin reset dropbox rails/mailers
         rails/active_storage api-docs].all? do |path|
        !request.path.start_with?("/#{path}")
      end
    end
  end
  resources :static_pages, only: [], path: 'demo-marketplace' do
    collection do
      get :product_list
      get '/unitedmasters' => :fashion_rocks, as: :fashion_rocks
    end
  end

  if Rails.application.credentials.global[:pages][:influencers]
    resources :influencers, only: [:index]
  end

  scope module: :webrtcservice, path: :webrtcservice do
    resources :authorizations, only: :create
    resources :webhooks, only: :create
    resources :bans, only: :create
  end
  resources :chat_channels, only: [] do
    resources :chat_messages, only: :index
  end
  resources :visitor_sources, only: [:create]

  match '*raw_slug/toggle_like' => 'not_found_or_title_parameterized#toggle_like', via: %i[get post],
        constraints: NotFoundOrTitleParameterized
  match '*raw_slug/preview_share' => 'not_found_or_title_parameterized#preview_share', via: %i[get post],
        constraints: NotFoundOrTitleParameterized

  # NOTE: you'll need to extand it for non-users as well in the future(for companies)
  match '*raw_slug/toggle_follow', to: 'not_found_or_title_parameterized#toggle_follow', via: %i[get post],
                                   constraints: NotFoundOrTitleParameterized
  match '*raw_slug/toggle_subscribe', to: 'not_found_or_title_parameterized#toggle_follow', via: %i[get post],
                                      constraints: NotFoundOrTitleParameterized
  match '*session_slug/toggle_wishlist_item', to: 'sessions#toggle_wishlist_item', via: %i[get post],
                                              constraints: NotFoundOrTitleParameterized

  get 's/:id' => 'shortener/shortened_urls#show'
  get '*raw_slug' => 'not_found_or_title_parameterized#user_or_channel_or_session_or_organization',
      constraints: NotFoundOrTitleParameterized
end
