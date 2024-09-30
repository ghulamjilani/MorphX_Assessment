# frozen_string_literal: true

Kernel.silence_warnings do
  MAILER_USER_ID_PARAM = 'uid'

  DEGRADABLE_LINK_CLASS = 'degradable'

  PAY_FOR_THIS_USER_CONTAINER = 'pay-for-this-user-container'

  BUSINESS_SECTION_IDENTIFIER = 'business-section-form'

  TEST_CC_NUMBER = %w[4111 1111 1111 1111].join

  RETURN_TO_AFTER_CONNECTING_ACCOUNT = 'return_to_after_connecting_account'

  REDIRECT_BACK_TO_AFTER_SIGNUP = 'redirect_back_to_after_signup'

  LONG_TEXTAREA_MAX_LENGTH = 2000

  # virtual attribute(do not confuse it with list_automatically_after_approved_by_admin)
  LIST_CHANNEL_IMMEDIATELY = 'list_immediately'

  GO_LIVEUNITE_COOKIE_KEY_NAME = 'goliveunite'

  module JoinInitializationTypes
    DASHBOARD           = 'dashboard'
    SESSION_SHOW        = 'sessionshow'
    USER_SHOW           = 'usershow'
    THANK_YOU           = 'thankyou'
    PREVIEW_PURCHASE    = 'previewpurchase'

    HEADER_NEXT_SESSION = 'headernextsession'
    PLAYER_OVERLAY      = 'playeroverlay'
  end

  module FreeSessionPublishedAutomaticallyReasons
    APPROVED_PRIVATE_AUTOMATICALLY_BECAUSE_OF_PREFERENCE = 'approved_private_automatically_because_of_preference'
    APPROVED_BECAUSE_OF_LIMIT                            = 'approved_because_of_limit'
  end

  SessionFormButtonTypeParameterName = 'clicked_button_type'
  module SessionFormButtonTypes
    # Save as Draft
    # Update Draft
    SAVE_AS_DRAFT     = 'draft'

    # Publish Private Session
    # Publish Session
    # Publish Private Session
    # Update Session
    # Submit for Approval
    SAVE_AS_NON_DRAFT = 'published'

    ALL = [SAVE_AS_DRAFT, SAVE_AS_NON_DRAFT].freeze
  end

  VIDEO_ID_FOR_SHARING = :vod_id

  def display_home_page_live_guide?
    !Rails.env.production?
  end

  # @result [Array] - example: [:birthdate, :email, :first_name, :gender, :last_name]
  def all_validation_skipable_user_attributes
    # NOTE: why? see https://github.com/npearson72/validation_skipper/blob/master/lib/validation_skipper.rb
    #      for DRYing and so that that you can forget about it for a while
    @all_validation_skipable_user_attributes ||= User.new
                                                     .public_methods(false)
                                                     .select { |m| m.to_s.start_with?('skip_') }
                                                     .collect { |m| m.to_s.gsub('skip_', '').gsub('_validation', '') }
                                                     .collect(&:parameterize)
                                                     .uniq
                                                     .map(&:to_sym)
  end

  def carrierwave_extension_white_list
    %w[jpg jpeg png bmp]
  end

  # @param [n_times] - example "2.times"
  # @param [fetch_user_for_organization] lambda that has to return [User] object that is assigned as organization owner/user
  def generate_real_looking_organization(n_times, fetch_user_for_organization)
    n_times.each do
      organization = Retryable.retryable(tries: 3, on: ActiveRecord::RecordInvalid) do
        FactoryBot.create(:organization, user: fetch_user_for_organization.call)
      end
      FactoryBot.create(:organization_logo, organization: organization)
      FactoryBot.create(:organization_cover, organization: organization)

      if [true, false].sample
        FactoryBot.create(:social_link,
                          link: "https://facebook.com/#{organization.name.parameterize}",
                          provider: SocialLink::Providers::FACEBOOK,
                          entity: organization)
      end

      if [true, false].sample
        FactoryBot.create(:social_link,
                          link: "https://twitter.com/#{organization.name.parameterize}",
                          provider: SocialLink::Providers::TWITTER,
                          entity: organization)
      end

      if [true, false].sample
        FactoryBot.create(:social_link,
                          link: "https://plus.google.com/#{organization.name.parameterize}",
                          provider: SocialLink::Providers::GPLUS,
                          entity: organization)
      end

      if [true, false].sample
        FactoryBot.create(:social_link,
                          link: "https://linkedin.com/#{organization.name.parameterize}",
                          provider: SocialLink::Providers::LINKEDIN,
                          entity: organization)
      end

      # rand(6).times do
      #  FactoryBot.create(:organization_membership, role: OrganizationMembership::Roles::ALL.sample, organization: organization)
      # end

      rand(1..3).times do
        channel = FactoryBot.create(:channel, organization: organization).tap do |p|
          p.list! if [true, false].sample
          5.times do
            post = FactoryBot.create(:blog_post, user: organization.user, channel: p)
            rand(5).times do
              comment_author = User.order(Arel.sql('RANDOM()')).limit(1).first
              comment = FactoryBot.create(:blog_comment, commentable: post, user: comment_author)
              rand(3).times do
                comment2_author = User.order(Arel.sql('RANDOM()')).limit(1).first
                FactoryBot.create(:blog_comment_on_comment, commentable: comment, user: comment2_author)
              end
            end
          end
        end

        rand(1..4).times do
          FactoryBot.create(:channel_invited_presentership,
                            status: ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED, channel: channel)
        end

        next unless [
          true, false
        ].sample

        FactoryBot.create(:channel_invited_presentership,
                          status: ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING, channel: channel)
      end

      organization.all_channels.listed.not_archived.limit(5).find_each do |channel|
        rand(2..5).times do
          post = FactoryBot.create(:blog_post_published, channel: channel, user: organization.user)
          rand(2..10).times do
            comment_author = User.order(Arel.sql('RANDOM()')).limit(1).first
            comment = FactoryBot.create(:blog_comment, commentable: post, user: comment_author)
            rand(1..5).times do
              comment_author = User.order(Arel.sql('RANDOM()')).limit(1).first
              FactoryBot.create(:blog_comment_on_comment, commentable: comment, user: comment_author)
            end
          end
        end
        rand(1..3).times { FactoryBot.create(:blog_post_hidden, channel: channel, user: organization.user) }
        rand(1..3).times { FactoryBot.create(:blog_post_draft, channel: channel, user: organization.user) }
        rand(1..3).times { FactoryBot.create(:blog_post_archived, channel: channel, user: organization.user) }
      end
    end
  end

  def create_mandatory_rates(user, session)
    raise 'Not Allowed' if Rails.env.production?

    Session::RateKeys::MANDATORY.each do |dimension|
      def session.can_rate?(_user, _dimension = nil)
        true
      end

      session.rate([1, 2, 3, 4, 5].sample, user, dimension)
    end
  end

  # emails which are notified about
  # * new users
  # * new pending channels
  # * presenters with too low balances
  # @return [String]
  def csr_recipient_emails
    # NOTE: if you need to update it, review all "csr_recipient_emails" uses first
    Admin.where(receive_manager_mailing: true).pluck(:email)
  end

  def friendly_id_reserved_words
    %w[
      400
      404
      406
      422
      500

      readme
      install
      xmlrpc
      feed
      atom
      rss
      index
      browserconfig

      admin
      assets
      atom
      browserconfig
      edit
      feed
      images
      index
      install
      javascripts
      login
      logout
      new
      channel
      presenter
      readme
      rss
      session
      stylesheets
      users
    ]
  end

  def omniauth_enabled?
    return false unless Rails.application.credentials.global.dig(:socials, :log_in, :enabled)

    facebook_omniauth_enabled? \
     || gplus_omniauth_enabled? \
     || twitter_omniauth_enabled? \
     || linkedin_omniauth_enabled? \
     || instagram_omniauth_enabled? \
     || zoom_omniauth_enabled? \
     || apple_omniauth_enabled?
  end

  def facebook_omniauth_enabled?
    !!Rails.application.credentials.global.dig(:socials, :log_in, :facebook, :enabled)
  end

  def gplus_omniauth_enabled?
    !!Rails.application.credentials.global.dig(:socials, :log_in, :gplus, :enabled)
  end

  def twitter_omniauth_enabled?
    !!Rails.application.credentials.global.dig(:socials, :log_in, :twitter, :enabled)
  end

  def linkedin_omniauth_enabled?
    !!Rails.application.credentials.global.dig(:socials, :log_in, :linkedin, :enabled)
  end

  def instagram_omniauth_enabled?
    !!Rails.application.credentials.global.dig(:socials, :log_in, :instagram, :enabled)
  end

  def zoom_omniauth_enabled?
    !!Rails.application.credentials.global.dig(:socials, :log_in, :zoom, :enabled)
  end

  def apple_omniauth_enabled?
    !!Rails.application.credentials.global.dig(:socials, :log_in, :apple, :enabled)
  end

  module TransactionTypes
    IMMERSIVE     = 'immersive_access'
    LIVESTREAM    = 'livestream_access'
    RECORDED      = 'recorded'
    RECORDING     = 'recording'
    BOOKING       = 'booking'
    DOCUMENT = 'document'

    REPLENISHMENT = 'replenishment'

    CHANNEL_SUBSCRIPTION = 'channel_subscription'
    CHANNEL_GIFT_SUBSCRIPTION = 'channel_gift_subscription'
    SERVICE_SUBSCRIPTION = 'service_subscription'

    ALL = [IMMERSIVE, LIVESTREAM, RECORDED, RECORDING, REPLENISHMENT, CHANNEL_SUBSCRIPTION, CHANNEL_GIFT_SUBSCRIPTION,
           SERVICE_SUBSCRIPTION, BOOKING, DOCUMENT].freeze
  end

  module Accounts
    # NOTE: if you need to add new account or want to rename existing
    #      make sure you saw lib/immerss_migrations.rb prior to that action
    #
    # Asset Account: Debit (increase) Credit (decrease)
    # Liability Account: Debit (decrease) Credit (increase)
    # Income Account: Debit (decrease) Credit (increase)
    # COGS Account: Debit (increase) Credit (decrease) (different type of expense accnt)
    # Expense Account: Debit (increase) Credit (decrease)
    #
    # Account Name | Account Type
    # Cash         | Asset  +
    # Merchant     | Asset  +
    #
    # Advance Purchase | Liability  +
    # Vendor Payable   | Liability  +
    # Sales Tax        | Liability  +
    #
    # SaaS Revenue                 | Income +
    # Interactive Session Revenue  | Income +
    # Simulcasting Session Revenue | Income +
    # VoD Revenue                  | Income +
    # Content Subscription Revenue | Income +
    # COGS Reimbursement           | Income + Miscellaneous Fees
    #
    # Vendor Earnings | COGS (Cost of Goods Sold)
    #
    # Boo-boo Account | Expense
    # Promo Account   | Expense
    # Merchant Fees   | Expense
    module Asset
      CASH                              = 'Cash'
      MERCHANT                          = 'Merchant'
    end

    module LongTermLiability
      # TODO: Check me
      CUSTOMER_CREDIT                   = 'Customer Credit'
    end

    module ShortTermLiability
      ADVANCE_PURCHASE                  = 'Advance Purchase'
      VENDOR_PAYABLE                    = 'Vendor Payable'
      SALES_TAX                         = 'Sales Tax'
    end

    module Income
      SAAS_REVENUE                      = 'SaaS Revenue' # Brand buys Immerss subscription plan
      IMMERSIVE_SESSION_REVENUE         = 'Immersive Session Revenue' # Interactive Session Revenue
      LIVESTREAM_SESSION_REVENUE        = 'Livestream Session Revenue' # Simulcasting Session Revenue
      RECORDED_SESSION_REVENUE          = 'Recorded Session Revenue' # VoD Revenue
      SUBSCRIPTION_REVENUE              = 'Subscription Revenue' # Content Subscription Revenue --- Consumer buys a subscription plan
      MISCELLANEOUS_FEES                = 'Miscellaneous Fees' # Includes: COGS Reimburcement Fees, Cancellation Fees and Co-presenters Fees

      SERVICE_FEES                      = 'Service Fees'

      # TODO: Check me
      RECORDING_REVENUE                 = 'Recording Revenue' # not used ?
    end

    module COGS
      # splitted 30/70 value of
      # channel subscription
      # immersive/livestream session
      # replay
      # recording
      VENDOR_EARNINGS = 'Vendor Earnings'

      # TODO: Check me
      IMMERSIVE_SESSION_VENDOR_EARNINGS  = 'Immersive Session Vendor Earnings'
      LIVESTREAM_SESSION_VENDOR_EARNINGS = 'Livestream Session Vendor Earnings'
      RECORDED_SESSION_VENDOR_EARNINGS   = 'Recorded Session Vendor Earnings'
      RECORDING_VENDOR_EARNINGS          = 'Recording Vendor Earnings'
    end

    module Expense
      BOO_BOO                           = 'Boo-Boo'
      PROMO                             = 'Promo'
      PRESENTER_COMMISION               = 'Presenter Commision' # Merchant Fees
      # TODO: Check me
      USER_COMMISION                    = 'User Commision'
    end

    # NOTE: if you update that constant, see spec/plutus_accounts_spec.rb
    ALL = Accounts.constants.reject { |c| c == :ALL }.collect do |scope|
      Accounts.const_get(scope).constants.collect do |inner_scope|
        Accounts.const_get(scope).const_get(inner_scope)
      end
    end.flatten
  end

  module ObtainTypes
    # free-trial or completely free
    FREE_IMMERSIVE = 'free_immersive'

    PAID_IMMERSIVE = 'paid_immersive'

    # free-trial or completely free
    FREE_LIVESTREAM = 'free_livestream'

    PAID_LIVESTREAM = 'paid_livestream'

    FREE_VOD = 'free_vod'
    PAID_VOD = 'paid_vod'

    FREE_RECORDING = 'free_recording'
    PAID_RECORDING = 'paid_recording'

    ALL = [
      FREE_IMMERSIVE,
      PAID_IMMERSIVE,

      FREE_LIVESTREAM,
      PAID_LIVESTREAM,

      FREE_VOD,
      PAID_VOD,

      FREE_RECORDING,
      PAID_RECORDING
    ].freeze
  end

  module PaymentMethods
    Braintree    = 'braintree'
    SystemCredit = 'system_credit'
  end
end

def linkedin_profile_domains
  [
    'af.linkedin.com',
    'al.linkedin.com',
    'dz.linkedin.com',
    'ar.linkedin.com',
    'au.linkedin.com',
    'at.linkedin.com',
    'bh.linkedin.com',
    'bd.linkedin.com',
    'be.linkedin.com',
    'bo.linkedin.com',
    'ba.linkedin.com',
    'br.linkedin.com',
    'bg.linkedin.com',
    'ca.linkedin.com',
    'cl.linkedin.com',
    'cn.linkedin.com',
    'co.linkedin.com',
    'cr.linkedin.com',
    'hr.linkedin.com',
    'cy.linkedin.com',
    'cz.linkedin.com',
    'dk.linkedin.com',
    'do.linkedin.com',
    'ec.linkedin.com',
    'eg.linkedin.com',
    'sv.linkedin.com',
    'ee.linkedin.com',
    'fi.linkedin.com',
    'fr.linkedin.com',
    'de.linkedin.com',
    'gh.linkedin.com',
    'gr.linkedin.com',
    'gt.linkedin.com',
    'hk.linkedin.com',
    'hu.linkedin.com',
    'is.linkedin.com',
    'in.linkedin.com',
    'id.linkedin.com',
    'ir.linkedin.com',
    'ie.linkedin.com',
    'il.linkedin.com',
    'it.linkedin.com',
    'jm.linkedin.com',
    'jp.linkedin.com',
    'jo.linkedin.com',
    'kz.linkedin.com',
    'ke.linkedin.com',
    'kr.linkedin.com',
    'kw.linkedin.com',
    'lv.linkedin.com',
    'lb.linkedin.com',
    'lt.linkedin.com',
    'lu.linkedin.com',
    'mk.linkedin.com',
    'my.linkedin.com',
    'mt.linkedin.com',
    'mu.linkedin.com',
    'mx.linkedin.com',
    'ma.linkedin.com',
    'np.linkedin.com',
    'nl.linkedin.com',
    'nz.linkedin.com',
    'ng.linkedin.com',
    'no.linkedin.com',
    'om.linkedin.com',
    'pk.linkedin.com',
    'pa.linkedin.com',
    'pe.linkedin.com',
    'ph.linkedin.com',
    'pl.linkedin.com',
    'pt.linkedin.com',
    'pr.linkedin.com',
    'qa.linkedin.com',
    'ro.linkedin.com',
    'ru.linkedin.com',
    'sa.linkedin.com',
    'sg.linkedin.com',
    'sk.linkedin.com',
    'si.linkedin.com',
    'za.linkedin.com',
    'es.linkedin.com',
    'lk.linkedin.com',
    'se.linkedin.com',
    'ch.linkedin.com',
    'tw.linkedin.com',
    'tz.linkedin.com',
    'th.linkedin.com',
    'tt.linkedin.com',
    'tn.linkedin.com',
    'tr.linkedin.com',
    'ug.linkedin.com',
    'ua.linkedin.com',
    'ae.linkedin.com',
    'uk.linkedin.com',
    'uy.linkedin.com',
    've.linkedin.com',
    'vn.linkedin.com',
    'zw.linkedin.com'
  ]
end

class String
  # NOTE: this return 0 if string is not numberic, otherwise it returns self
  def to_immerss_i
    numeric = begin
      !Float(self).nil?
    rescue StandardError
      false
    end

    numeric ? self : 0
  end
end

class AllFormatsEnaledPolicy
  def web?(_user, _method)
    true
  end

  def email?(_user, _method)
    true
  end

  def sms?(_user, _method)
    true
  end
end

class WebOnlyFormatPolicy
  def web?(_user, _method)
    true
  end

  def email?(_user, _method)
    false
  end

  def sms?(_user, _method)
    false
  end
end

class EmailOnlyFormatPolicy
  def web?(_user, _method)
    false
  end

  def email?(_user, _method)
    true
  end

  def sms?(_user, _method)
    false
  end
end

class SmsOnlyFormatPolicy
  def web?(_user, _method)
    false
  end

  def email?(_user, _method)
    false
  end

  def sms?(_user, _method)
    true
  end
end

# proper_env = Rails.env.development? || Rails.env.qa?
# loaded_from_console = defined?(Rails::Console) # Debugging?
# if proper_env || loaded_from_console
#   # require Rails.root.join('lib/dev/helpers')
# end
