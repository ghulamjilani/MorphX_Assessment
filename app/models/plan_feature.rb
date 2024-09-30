# frozen_string_literal: true
class PlanFeature < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  CODES = %w[storage streaming_time interactive_streaming_time transcoding_time max_channels_count max_session_duration
             mobile_apps multi_currencies channel_subscriptions ppv gift_channel_subscription instream_shopping online_store
             manage_admins max_admins_count manage_creators max_creators_count constant_contact audience_chat community_blog
             add_free_streaming multi_language full_hd_uploads video_transcoding ip_cam encoder embed analytics statistics
             support_level free_trial multi_room interactive_stream featured_section max_interactive_participants
             grace_days suspended_days trial_suspended_days co_hosting document_management private_sessions donations direct_messaging split_revenue_percent].freeze
  TYPES = %w[integer boolean string].freeze
  SESSION_CODES = %w[max_session_duration streaming_time interactive_streaming_time ppv ip_cam encoder interactive_stream instream_shopping
                     max_interactive_participants grace_days co_hosting private_sessions].freeze
  has_many :feature_parameters

  validates :code, presence: true, uniqueness: true
end
