# frozen_string_literal: true

require 'swagger_helper'

describe 'Sessions', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/sessions' do
    get 'Get upcoming sessions for user' do
      tags 'User::Sessions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :channel_id, in: :query, type: :integer
      parameter name: :presenter_id, in: :query, type: :integer
      parameter name: :organization_id, in: :query, type: :integer
      %w[start_at end_at].each do |param|
        parameter name: "#{param}_from".to_sym, in: :query, type: :string, format: 'date-time'
        parameter name: "#{param}_to".to_sym, in: :query, type: :string, format: 'date-time'
      end
      parameter name: :duration_from, in: :query, type: :integer
      parameter name: :duration_to, in: :query, type: :integer
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'start_at', 'end_at'. Default: 'start_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/channels/{channel_id}/sessions' do
    get 'Get upcoming sessions for user' do
      tags 'User::Sessions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :channel_id, in: :path, type: :integer
      parameter name: :presenter_id, in: :query, type: :integer
      parameter name: :organization_id, in: :query, type: :integer
      %w[start_at end_at].each do |param|
        parameter name: "#{param}_from".to_sym, in: :query, type: :string, format: 'date-time'
        parameter name: "#{param}_to".to_sym, in: :query, type: :string, format: 'date-time'
      end
      parameter name: :duration_from, in: :query, type: :integer
      parameter name: :duration_to, in: :query, type: :integer
      parameter name: :order_by, in: :query, type: :string,
                description: "Valid values are: 'start_at', 'end_at'. Default: 'start_at'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'asc'"
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/sessions/{id}' do
    get 'Get session info' do
      tags 'User::Sessions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/sessions/new' do
    get 'Get new session default attributes' do
      tags 'User::Sessions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :adult, in: :query, type: :string, description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :age_restrictions, in: :query, type: :integer
      parameter name: :allow_chat, in: :query, type: :string, description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :autostart, in: :query, type: :string, description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :channel_id, in: :query, type: :integer
      parameter name: :custom_description_field_label, in: :query, type: :string
      parameter name: :custom_description_field_value, in: :query, type: :string
      parameter name: :description, in: :query, type: :string
      parameter name: :device_type, in: :query, type: :string
      parameter name: :duration, in: :query, type: :integer
      parameter name: :free_trial_for_first_time_participants, in: :query, type: :string,
                description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :immersive_access_cost, in: :query, type: :string
      parameter name: :immersive_free_slots, in: :query, type: :integer
      parameter name: :immersive_free_trial, in: :query, type: :string,
                description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :immersive_free, in: :query, type: :string, description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :immersive_type, in: :query, type: :string
      parameter name: :immersive, in: :query, type: :string
      parameter name: :level, in: :query, type: :string
      parameter name: :livestream_access_cost, in: :query, type: :string
      parameter name: :livestream_free_slots, in: :query, type: :integer
      parameter name: :livestream_free_trial, in: :query, type: :string
      parameter name: :livestream_free, in: :query, type: :string
      parameter name: :livestream, in: :query, type: :string
      parameter name: :max_number_of_immersive_participants, in: :query, type: :integer
      parameter name: :min_number_of_immersive_and_livestream_participants, in: :query, type: :integer
      parameter name: :pre_time, in: :query, type: :integer,
                description: '"All Levels", "Beginner", "Intermediate", "Advanced"'
      parameter name: :presenter_id, in: :query, type: :integer
      parameter name: :private, in: :query, type: :string, description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :publish_after_requested_free_session_is_satisfied_by_admin, in: :query, type: :string,
                description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :record, in: :query, type: :string
      parameter name: :recorded_access_cost, in: :query, type: :string
      parameter name: :recorded_free, in: :query, type: :string, description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :recurring_settings, in: :query, type: :string,
                description: '{"days"=>["friday"], "until"=>"occurrence", "occurrence"=>"1"}'
      parameter name: :requested_free_session_reason, in: :query, type: :string
      parameter name: :service_type, in: :query, type: :string
      parameter name: :start_at, in: :query, type: :string
      parameter name: :start_now, in: :query, type: :string, description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :title, in: :query, type: :string
      parameter name: :twitter_feed_title, in: :query, type: :string
      parameter name: :ffmpegservice_account_id, in: :query, type: :integer
      parameter name: :recording_layout, in: :query, type: :string,
                description: '"grid", "presenter_only", "presenter_focus". Default: "grid"'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/channels/{channel_id}/sessions/new' do
    get 'Get new session default attributes' do
      tags 'User::Sessions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :channel_id, in: :path, type: :integer
      parameter name: :adult, in: :query, type: :string, description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :age_restrictions, in: :query, type: :integer
      parameter name: :allow_chat, in: :query, type: :string, description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :autostart, in: :query, type: :string, description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :custom_description_field_label, in: :query, type: :string
      parameter name: :custom_description_field_value, in: :query, type: :string
      parameter name: :description, in: :query, type: :string
      parameter name: :device_type, in: :query, type: :string
      parameter name: :duration, in: :query, type: :integer
      parameter name: :free_trial_for_first_time_participants, in: :query, type: :string,
                description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :immersive_access_cost, in: :query, type: :string
      parameter name: :immersive_free_slots, in: :query, type: :integer
      parameter name: :immersive_free_trial, in: :query, type: :string,
                description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :immersive_free, in: :query, type: :string, description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :immersive_type, in: :query, type: :string
      parameter name: :immersive, in: :query, type: :string
      parameter name: :level, in: :query, type: :string
      parameter name: :livestream_access_cost, in: :query, type: :string
      parameter name: :livestream_free_slots, in: :query, type: :integer
      parameter name: :livestream_free_trial, in: :query, type: :string
      parameter name: :livestream_free, in: :query, type: :string
      parameter name: :livestream, in: :query, type: :string
      parameter name: :max_number_of_immersive_participants, in: :query, type: :integer
      parameter name: :min_number_of_immersive_and_livestream_participants, in: :query, type: :integer
      parameter name: :pre_time, in: :query, type: :integer,
                description: '"All Levels", "Beginner", "Intermediate", "Advanced"'
      parameter name: :presenter_id, in: :query, type: :integer
      parameter name: :private, in: :query, type: :string, description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :publish_after_requested_free_session_is_satisfied_by_admin, in: :query, type: :string,
                description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :record, in: :query, type: :string
      parameter name: :recorded_access_cost, in: :query, type: :string
      parameter name: :recorded_free, in: :query, type: :string, description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :recurring_settings, in: :query, type: :string,
                description: '{"days"=>["friday"], "until"=>"occurrence", "occurrence"=>"1"}'
      parameter name: :requested_free_session_reason, in: :query, type: :string
      parameter name: :service_type, in: :query, type: :string
      parameter name: :start_at, in: :query, type: :string
      parameter name: :start_now, in: :query, type: :string, description: 'Type: checkbox. Pass "1" if checked'
      parameter name: :title, in: :query, type: :string
      parameter name: :twitter_feed_title, in: :query, type: :string
      parameter name: :ffmpegservice_account_id, in: :query, type: :integer
      parameter name: :recording_layout, in: :query, type: :string,
                description: '"grid", "presenter_only", "presenter_focus". Default: "grid"'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/sessions' do
    post 'Create new session' do
      tags 'User::Sessions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :adult, in: :query, type: :boolean
      parameter name: :age_restrictions, in: :query, type: :integer
      parameter name: :allow_chat, in: :query, type: :boolean
      parameter name: :autostart, in: :query, type: :boolean
      parameter name: :channel_id, in: :query, type: :integer
      parameter name: :custom_description_field_label, in: :query, type: :string
      parameter name: :custom_description_field_value, in: :query, type: :string
      parameter name: :description, in: :query, type: :string
      parameter name: :device_type, in: :query, type: :string
      parameter name: :duration, in: :query, type: :integer
      parameter name: :free_trial_for_first_time_participants, in: :query, type: :boolean
      parameter name: :immersive_access_cost, in: :query, type: :string
      parameter name: :immersive_free_slots, in: :query, type: :integer
      parameter name: :immersive_free_trial, in: :query, type: :boolean
      parameter name: :immersive_free, in: :query, type: :boolean
      parameter name: :immersive_type, in: :query, type: :string
      parameter name: :immersive, in: :query, type: :string
      parameter name: :level, in: :query, type: :string
      parameter name: :list_ids, in: :query, type: :array, items: { type: :integer }
      parameter name: :livestream_access_cost, in: :query, type: :string
      parameter name: :livestream_free_slots, in: :query, type: :integer
      parameter name: :livestream_free_trial, in: :query, type: :string
      parameter name: :livestream_free, in: :query, type: :string
      parameter name: :livestream, in: :query, type: :string
      parameter name: :max_number_of_immersive_participants, in: :query, type: :integer
      parameter name: :min_number_of_immersive_and_livestream_participants, in: :query, type: :integer
      parameter name: :only_ppv, in: :query, type: :boolean
      parameter name: :only_subscription, in: :query, type: :boolean
      parameter name: :pre_time, in: :query, type: :integer,
                description: '"All Levels", "Beginner", "Intermediate", "Advanced"'
      parameter name: :presenter_id, in: :query, type: :integer
      parameter name: :private, in: :query, type: :boolean
      parameter name: :publish_after_requested_free_session_is_satisfied_by_admin, in: :query, type: :boolean
      parameter name: :record, in: :query, type: :string
      parameter name: :recorded_access_cost, in: :query, type: :string
      parameter name: :recorded_free, in: :query, type: :boolean
      parameter name: :recurring_settings, in: :query, type: :string,
                description: '{"days"=>["friday"], "until"=>"occurrence", "occurrence"=>"1"}'
      parameter name: :requested_free_session_reason, in: :query, type: :string
      parameter name: :service_type, in: :query, type: :string
      parameter name: :start_at, in: :query, type: :string
      parameter name: :start_now, in: :query, type: :boolean
      parameter name: :title, in: :query, type: :string
      parameter name: :twitter_feed_title, in: :query, type: :string
      parameter name: :ffmpegservice_account_id, in: :query, type: :integer
      parameter name: :recording_layout, in: :query, type: :string,
                description: '"grid", "presenter_only", "presenter_focus". Default: "grid"'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/channels/{channel_id}/sessions' do
    post 'Create new session' do
      tags 'User::Sessions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :channel_id, in: :path, type: :integer
      parameter name: :adult, in: :query, type: :boolean
      parameter name: :age_restrictions, in: :query, type: :integer
      parameter name: :allow_chat, in: :query, type: :boolean
      parameter name: :autostart, in: :query, type: :boolean
      parameter name: :custom_description_field_label, in: :query, type: :string
      parameter name: :custom_description_field_value, in: :query, type: :string
      parameter name: :description, in: :query, type: :string
      parameter name: :device_type, in: :query, type: :string
      parameter name: :duration, in: :query, type: :integer
      parameter name: :free_trial_for_first_time_participants, in: :query, type: :boolean
      parameter name: :immersive_access_cost, in: :query, type: :string
      parameter name: :immersive_free_slots, in: :query, type: :integer
      parameter name: :immersive_free_trial, in: :query, type: :boolean
      parameter name: :immersive_free, in: :query, type: :boolean
      parameter name: :immersive_type, in: :query, type: :string
      parameter name: :immersive, in: :query, type: :string
      parameter name: :level, in: :query, type: :string
      parameter name: :list_ids, in: :query, type: :array, items: { type: :integer }
      parameter name: :livestream_access_cost, in: :query, type: :string
      parameter name: :livestream_free_slots, in: :query, type: :integer
      parameter name: :livestream_free_trial, in: :query, type: :string
      parameter name: :livestream_free, in: :query, type: :string
      parameter name: :livestream, in: :query, type: :string
      parameter name: :max_number_of_immersive_participants, in: :query, type: :integer
      parameter name: :min_number_of_immersive_and_livestream_participants, in: :query, type: :integer
      parameter name: :only_ppv, in: :query, type: :boolean
      parameter name: :only_subscription, in: :query, type: :boolean
      parameter name: :pre_time, in: :query, type: :integer,
                description: '"All Levels", "Beginner", "Intermediate", "Advanced"'
      parameter name: :presenter_id, in: :query, type: :integer
      parameter name: :private, in: :query, type: :boolean
      parameter name: :publish_after_requested_free_session_is_satisfied_by_admin, in: :query, type: :boolean
      parameter name: :record, in: :query, type: :string
      parameter name: :recorded_access_cost, in: :query, type: :string
      parameter name: :recorded_free, in: :query, type: :boolean
      parameter name: :recording_layout, in: :query, type: :string,
                description: '"grid", "presenter_only", "presenter_focus". Default: "grid"'
      parameter name: :recurring_settings, in: :query, type: :string,
                description: '{"days"=>["friday"], "until"=>"occurrence", "occurrence"=>"1"}'
      parameter name: :requested_free_session_reason, in: :query, type: :string
      parameter name: :service_type, in: :query, type: :string
      parameter name: :start_at, in: :query, type: :string
      parameter name: :start_now, in: :query, type: :boolean
      parameter name: :title, in: :query, type: :string
      parameter name: :twitter_feed_title, in: :query, type: :string
      parameter name: :ffmpegservice_account_id, in: :query, type: :integer
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/sessions/{id}' do
    put 'Update session' do
      tags 'User::Sessions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :adult, in: :query, type: :boolean
      parameter name: :age_restrictions, in: :query, type: :integer
      parameter name: :allow_chat, in: :query, type: :boolean
      parameter name: :autostart, in: :query, type: :boolean
      parameter name: :custom_description_field_label, in: :query, type: :string
      parameter name: :custom_description_field_value, in: :query, type: :string
      parameter name: :description, in: :query, type: :string
      parameter name: :device_type, in: :query, type: :string
      parameter name: :duration, in: :query, type: :integer
      parameter name: :free_trial_for_first_time_participants, in: :query, type: :boolean
      parameter name: :immersive_access_cost, in: :query, type: :string
      parameter name: :immersive_free_slots, in: :query, type: :integer
      parameter name: :immersive_free_trial, in: :query, type: :boolean
      parameter name: :immersive_free, in: :query, type: :boolean
      parameter name: :immersive_type, in: :query, type: :string
      parameter name: :immersive, in: :query, type: :string
      parameter name: :level, in: :query, type: :string
      parameter name: :livestream_access_cost, in: :query, type: :string
      parameter name: :livestream_free_slots, in: :query, type: :integer
      parameter name: :livestream_free_trial, in: :query, type: :string
      parameter name: :livestream_free, in: :query, type: :string
      parameter name: :livestream, in: :query, type: :string
      parameter name: :max_number_of_immersive_participants, in: :query, type: :integer
      parameter name: :min_number_of_immersive_and_livestream_participants, in: :query, type: :integer
      parameter name: :only_ppv, in: :query, type: :boolean
      parameter name: :only_subscription, in: :query, type: :boolean
      parameter name: :pre_time, in: :query, type: :integer,
                description: '"All Levels", "Beginner", "Intermediate", "Advanced"'
      parameter name: :presenter_id, in: :query, type: :integer
      parameter name: :private, in: :query, type: :boolean
      parameter name: :publish_after_requested_free_session_is_satisfied_by_admin, in: :query, type: :boolean
      parameter name: :record, in: :query, type: :string
      parameter name: :recorded_access_cost, in: :query, type: :string
      parameter name: :recorded_free, in: :query, type: :boolean
      parameter name: :recording_layout, in: :query, type: :string,
                description: '"grid", "presenter_only", "presenter_focus". Default: "grid"'
      parameter name: :recurring_settings, in: :query, type: :string,
                description: '{"days"=>["friday"], "until"=>"occurrence", "occurrence"=>"1"}'
      parameter name: :requested_free_session_reason, in: :query, type: :string
      parameter name: :service_type, in: :query, type: :string
      parameter name: :start_at, in: :query, type: :string
      parameter name: :start_now, in: :query, type: :boolean
      parameter name: :title, in: :query, type: :string
      parameter name: :twitter_feed_title, in: :query, type: :string
      parameter name: :ffmpegservice_account_id, in: :query, type: :integer
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/sessions/nearest_session' do
    get 'Get nearest session for user' do
      tags 'User::Sessions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/sessions/{id}/confirm_purchase' do
    post 'Obtain access to session' do
      tags 'User::Sessions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :type, in: :query, type: :string, required: true,
                description: "Valid values: 'free_immersive', 'paid_immersive', 'free_livestream', 'paid_livestream', 'free_vod', 'paid_vod'"
      parameter name: :discount, in: :query, type: :string
      parameter name: :provider, in: :query, type: :string, description: "Valid values: 'paypal'"
      parameter name: :stripe_token, in: :query, type: :string
      parameter name: :stripe_card, in: :query, type: :string

      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/sessions/{id}' do
    delete 'Cancel session' do
      tags 'User::Sessions'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true
      parameter name: :id, in: :path, type: :string, required: true
      parameter name: :cancel_reason_id, in: :query, type: :integer, required: true

      response '200', 'Found' do
        run_test!
      end
    end
  end
end
