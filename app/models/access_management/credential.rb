# frozen_string_literal: true
module AccessManagement
  class Credential < AccessManagement::ApplicationRecord
    include ActiveModel::ForbiddenAttributesProtection
    include ModelConcerns::ActiveModel::Extensions

    module Codes
      ADD_PRODUCTS_TO_SESSION                   = 'add_products_to_session'
      ARCHIVE_CHANNEL                           = 'archive_channel'
      CANCEL_SESSION                            = 'cancel_session'
      CLONE_SESSION                             = 'clone_session'
      CREATE_CHANNEL                            = 'create_channel'
      CREATE_RECORDING                          = 'create_recording'
      CREATE_SESSION                            = 'create_session'
      DELETE_RECORDING                          = 'delete_recording'
      DELETE_REPLAY                             = 'delete_replay'
      EDIT_CHANNEL                              = 'edit_channel'
      EDIT_RECORDING                            = 'edit_recording'
      EDIT_REPLAY                               = 'edit_replay'
      EDIT_SESSION                              = 'edit_session'
      END_SESSION                               = 'end_session'
      INVITE_TO_SESSION                         = 'invite_to_session'
      MAILING                                   = 'mailing'
      MANAGE_ADMIN                              = 'manage_admin'
      MANAGE_BLOG_POST                          = 'manage_blog_post'
      MANAGE_BOOKING                            = 'manage_booking'
      MANAGE_BUSINESS_PLAN                      = 'manage_business_plan'
      MANAGE_CHANNEL_PARTNER_SUBSCRIPTIONS      = 'manage_channel_partner_subscriptions'
      MANAGE_CHANNEL_SUBSCRIPTION               = 'manage_channel_subscription'
      MANAGE_CREATOR                            = 'manage_creator'
      MANAGE_DOCUMENTS                          = 'manage_documents'
      MANAGE_ENTERPRISE_MEMBER                  = 'manage_enterprise_member'
      MANAGE_ORGANIZATION                       = 'manage_organization'
      MANAGE_PAYMENT_METHOD                     = 'manage_payment_method'
      MANAGE_POLLS                              = 'manage_polls'
      MANAGE_PRODUCT                            = 'manage_product'
      MANAGE_ROLES                              = 'manage_roles'
      MODERATE_BLOG_POST                        = 'moderate_blog_post'
      MODERATE_CHANNEL_CONVERSATION             = 'moderate_channel_conversation'
      MODERATE_COMMENTS_AND_REVIEWS             = 'moderate_comments_and_reviews'
      MULTIROOM_CONFIG                          = 'multiroom_config'
      PARTICIPATE_CHANNEL_CONVERSATION          = 'participate_channel_conversation'
      REFUND                                    = 'refund'
      START_SESSION                             = 'start_session'
      TRANSCODE_RECORDING                       = 'transcode_recording'
      TRANSCODE_REPLAY                          = 'transcode_replay'
      VIEW_BILLING_REPORT                       = 'view_billing_report'
      VIEW_CONTENT                              = 'view_content'
      VIEW_REVENUE_REPORT                       = 'view_revenue_report'
      VIEW_USER_REPORT                          = 'view_user_report'
      VIEW_VIDEO_REPORT                         = 'view_video_report'

      ALL = [
        ADD_PRODUCTS_TO_SESSION, ARCHIVE_CHANNEL, CANCEL_SESSION,
        CLONE_SESSION, CREATE_CHANNEL, CREATE_RECORDING, CREATE_SESSION,
        DELETE_RECORDING, DELETE_REPLAY, EDIT_CHANNEL, EDIT_RECORDING,
        EDIT_REPLAY, EDIT_SESSION, END_SESSION, INVITE_TO_SESSION,
        MAILING, MANAGE_ADMIN, MANAGE_BLOG_POST, MANAGE_BUSINESS_PLAN,
        MANAGE_CHANNEL_PARTNER_SUBSCRIPTIONS, MANAGE_CHANNEL_SUBSCRIPTION,
        MANAGE_CREATOR, MANAGE_DOCUMENTS,
        MANAGE_ENTERPRISE_MEMBER, MANAGE_ORGANIZATION,
        MANAGE_PAYMENT_METHOD, MANAGE_PRODUCT, MANAGE_ROLES,
        MODERATE_BLOG_POST, MODERATE_CHANNEL_CONVERSATION, MODERATE_COMMENTS_AND_REVIEWS,
        MULTIROOM_CONFIG, PARTICIPATE_CHANNEL_CONVERSATION, REFUND, START_SESSION,
        TRANSCODE_RECORDING, TRANSCODE_REPLAY, VIEW_BILLING_REPORT,
        VIEW_CONTENT, VIEW_REVENUE_REPORT, VIEW_USER_REPORT,
        VIEW_VIDEO_REPORT, MANAGE_BOOKING, MANAGE_POLLS
      ].freeze

      def self.inactive
        codes = []
        codes << MANAGE_DOCUMENTS unless Rails.application.credentials.global[:is_document_management_enabled]
        codes
      end

      def self.active
        ALL - inactive
      end
    end

    belongs_to :category, class_name: 'AccessManagement::Category', foreign_key: :access_management_category_id
    belongs_to :type, class_name: 'AccessManagement::Type', foreign_key: :access_management_type_id

    validates :code, :name, presence: true
    validates :code, inclusion: { in: Codes::ALL }

    scope :active, -> { where(code: Codes.active, is_enabled: true) }
    scope :inactive, -> { where(code: Codes.inactive).or(where(is_enabled: false)) }
    scope :by_type, ->(name) { joins(:type).where(access_management_types: { name: name }) }

    # the high level of credential state which based on is_enabled? and third properties of the system
    def active?
      Codes.inactive.exclude?(code) && is_enabled?
    end
  end
end
