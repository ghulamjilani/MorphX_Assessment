# frozen_string_literal: true
class LogTransaction < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ActionView::Helpers::NumberHelper
  scope :by_data_contains, lambda { |q|
    LogTransaction.where('log_transactions.data ILIKE ?', "%#{q}%")
  }

  def self.ransackable_scopes(_auth_object = nil)
    [:by_data_contains]
  end
  serialize :data, Hash
  paginates_per 5

  belongs_to :user
  belongs_to :abstract_session, polymorphic: true # TODO: rename to purchased_item
  belongs_to :payment_transaction, polymorphic: true

  # disable STI
  self.inheritance_column = :_type_disabled

  module Types
    CREDIT_REPLENISHMENT                       = 'credit_replenishment'
    MONEY_REFUND                               = 'money_refund'
    NET_INCOME                                 = 'net_income'

    LIVE_OPT_OUT_FROM_ABSTRACT_SESSION_AFTER_PAYING = 'opt_out_from_abstract_session_after_paying'
    VOD_OPT_OUT_FROM_SESSION_AFTER_PAYING           = 'vod_opt_out_from_session_after_paying'

    PAID_FOR_CO_PRESENTER                      = 'paid_for_co_presenter'
    SESSION_IMMERSIVE_FEE                      = 'session_immersive_fee'

    TODO_COMPLETING = 'todo_completing'

    REFERRAL_FEE = 'referral_fee'

    PURCHASED_INTERACTIVE_ABSTRACT_SESSION                 = 'purchased_abstract_session'
    PURCHASED_LIVESTREAM_SESSION                           = 'purchased_livestream_session'
    PURCHASED_RECORDED_SESSION                             = 'purchased_recorded_session'
    PURCHASED_RECORDING                                    = 'purchased_recording'

    PURCHASED_CHANNEL_SUBSCRIPTION      = 'purchased_channel_subscription'
    PURCHASED_CHANNEL_GIFT_SUBSCRIPTION = 'purchased_channel_gift_subscription'
    PURCHASED_SERVICE_SUBSCRIPTION      = 'purchased_service_subscription'

    SOLD_CHANNEL_SUBSCRIPTION      = 'sold_channel_subscription'
    SOLD_CHANNEL_GIFT_SUBSCRIPTION = 'sold_channel_gift_subscription'

    BOOKING = 'booking'
    DOCUMENT = 'document'

    PURCHASED_IMMERSIVE_ABSTRACT_SESSION_VIA_SYSTEM_CREDIT = 'purchased_abstract_session_via_system_credit'
    PURCHASED_LIVESTREAM_SESSION_VIA_SYSTEM_CREDIT         = 'purchased_livestream_session_via_system_credit'
    PURCHASED_RECORDED_SESSION_VIA_SYSTEM_CREDIT           = 'purchased_recorded_session_via_system_credit'
    PURCHASED_RECORDING_VIA_SYSTEM_CREDIT                  = 'purchased_recording_via_system_credit'

    SESSION_CANCELLATION_PENALTY                           = 'session_cancellation_penalty'
    SYSTEM_CREDIT_REFUND                                   = 'system_credit_refund'

    BOO_BOO_CSR_REFUND                                     = 'boo_boo_csr_refund'
    MONEY_CSR_REFUND                                       = 'money_csr_refund'

    ALL = [
      BOOKING,
      DOCUMENT,
      BOO_BOO_CSR_REFUND,
      CREDIT_REPLENISHMENT,
      LIVE_OPT_OUT_FROM_ABSTRACT_SESSION_AFTER_PAYING,
      MONEY_CSR_REFUND,
      MONEY_REFUND,
      NET_INCOME,
      PAID_FOR_CO_PRESENTER,
      PURCHASED_INTERACTIVE_ABSTRACT_SESSION,
      PURCHASED_IMMERSIVE_ABSTRACT_SESSION_VIA_SYSTEM_CREDIT,
      PURCHASED_LIVESTREAM_SESSION,
      PURCHASED_LIVESTREAM_SESSION_VIA_SYSTEM_CREDIT,
      PURCHASED_RECORDED_SESSION,
      PURCHASED_RECORDED_SESSION_VIA_SYSTEM_CREDIT,
      PURCHASED_RECORDING,
      PURCHASED_RECORDING_VIA_SYSTEM_CREDIT,
      REFERRAL_FEE,
      SESSION_CANCELLATION_PENALTY,
      SESSION_IMMERSIVE_FEE,
      SYSTEM_CREDIT_REFUND,
      TODO_COMPLETING,
      PURCHASED_CHANNEL_SUBSCRIPTION,
      PURCHASED_CHANNEL_GIFT_SUBSCRIPTION,
      PURCHASED_SERVICE_SUBSCRIPTION,
      SOLD_CHANNEL_SUBSCRIPTION,
      SOLD_CHANNEL_GIFT_SUBSCRIPTION
    ].freeze
  end

  validates :type, inclusion: { in: Types::ALL }

  # NOTE: - for certain log transactions abstract_session could be nil(like credit replenishment kind of transactions)
  validates :abstract_session, presence: true, if: proc { |obj|
    !obj.type.nil? && [Types::CREDIT_REPLENISHMENT, Types::BOO_BOO_CSR_REFUND, Types::TODO_COMPLETING].exclude?(obj.type)
  }
  after_create :notify_user
  after_commit :create_reports

  def as_html
    case type
    when Types::BOOKING
      "#{abstract_session.name} - booking"
    when Types::TODO_COMPLETING
      I18n.t('log_transactions.todo_completing')
    when Types::NET_INCOME
      if abstract_session_type == 'StripeDb::Plan'
        "#{abstract_session.im_name} - net income"
      else
        data[:session_link] =
          %(<a target="_blank" href="#{abstract_session.absolute_path}">#{abstract_session.always_present_title}</a>)
        I18n.t('log_transactions.net_income', **data)
      end
    when Types::SESSION_IMMERSIVE_FEE
      data[:session_link] =
        %(<a target="_blank" href="#{abstract_session.absolute_path}">#{abstract_session.always_present_title}</a>)
      I18n.t('log_transactions.session_immersive_fee', **data)
    when Types::REFERRAL_FEE
      data[:session_link] =
        %(<a target="_blank" href="#{abstract_session.absolute_path}">#{abstract_session.always_present_title}</a>)
      I18n.t('log_transactions.referral_fee', **data)
    when Types::SESSION_CANCELLATION_PENALTY
      data[:session_link] =
        %(<a target="_blank" href="#{abstract_session.absolute_path}">#{abstract_session.always_present_title}</a>)
      data[:display_names] = data[:display_names].join(', ')

      I18n.t('log_transactions.session_cancellation_penalty', **data)
    when Types::PURCHASED_SERVICE_SUBSCRIPTION
      I18n.t('models.log_transaction.as_html', title: abstract_session.nickname,
                                               service_name: Rails.application.credentials.global[:service_name])
    when Types::PURCHASED_CHANNEL_SUBSCRIPTION, Types::SOLD_CHANNEL_SUBSCRIPTION
      begin
        channel = Channel.find_by(stripe_id: abstract_session.product)
        data[:channel_link] =
          begin
            %(<a target="_blank" href="#{channel.absolute_path}">#{channel.always_present_title}</a>)
          rescue StandardError
            'unknown'
          end
        "Subscribed to Channel #{data[:channel_link]} with #{abstract_session.nickname}"
      rescue StandardError => e
        'Subscribed to Channel'
      end
    when Types::PURCHASED_CHANNEL_GIFT_SUBSCRIPTION, Types::SOLD_CHANNEL_GIFT_SUBSCRIPTION
      channel = Channel.find_by(stripe_id: abstract_session.product)
      data[:channel_link] =
        begin
          %(<a target="_blank" href="#{channel.absolute_path}">#{channel.always_present_title}</a>)
        rescue StandardError
          ''
        end
      "Gift Subscription for #{data[:user_name]} to Channel #{data[:channel_link]} with #{abstract_session.nickname}"
    when Types::PURCHASED_INTERACTIVE_ABSTRACT_SESSION
      data[:abstract_session_link] =
        %(<a target="_blank" href="#{abstract_session.absolute_path}">#{abstract_session.always_present_title}</a>)

      if data.key?(:credit_card_number)
        I18n.t('log_transactions.purchased_immersive_abstract_session_with_credit_card', **data)
      elsif data.key?(:paypal_payer_email)
        I18n.t('log_transactions.purchased_immersive_abstract_session_with_paypal', **data)
      else
        data.inspect
        # raise "can not interpret #{data.inspect}"
      end

    when Types::PURCHASED_IMMERSIVE_ABSTRACT_SESSION_VIA_SYSTEM_CREDIT
      data[:abstract_session_link] =
        %(<a target="_blank" href="#{abstract_session.absolute_path}">#{abstract_session.always_present_title}</a>)

      I18n.t('log_transactions.purchased_immersive_abstract_session_with_system_credit', **data)
    when Types::PURCHASED_LIVESTREAM_SESSION
      data[:session_link] =
        %(<a target="_blank" href="#{abstract_session.absolute_path}">#{abstract_session.always_present_title}</a>)

      if data.key?(:credit_card_number)
        I18n.t('log_transactions.purchased_livestream_session_with_credit_card', **data)
      elsif data.key?(:paypal_payer_email)
        I18n.t('log_transactions.purchased_livestream_session_with_paypal', **data)
      else
        data.inspect
        # raise "can not interpret #{data.inspect}"
      end

    when Types::PURCHASED_LIVESTREAM_SESSION_VIA_SYSTEM_CREDIT
      data[:session_link] =
        %(<a target="_blank" href="#{abstract_session.absolute_path}">#{abstract_session.always_present_title}</a>)

      I18n.t('log_transactions.purchased_livestream_session_with_system_credit', **data)
    when Types::PURCHASED_RECORDED_SESSION
      data[:session_link] =
        %(<a target="_blank" href="#{abstract_session.absolute_path}">#{abstract_session.always_present_title}</a>)

      if data.key?(:credit_card_number)
        I18n.t('log_transactions.purchased_recorded_session_with_credit_card', **data)
      elsif data.key?(:paypal_payer_email)
        I18n.t('log_transactions.purchased_recorded_session_with_paypal', **data)
      else
        data.inspect
        # raise "can not interpret #{data.inspect}"
      end

    when Types::PURCHASED_RECORDED_SESSION_VIA_SYSTEM_CREDIT
      data[:session_link] =
        %(<a target="_blank" href="#{abstract_session.absolute_path}">#{abstract_session.always_present_title}</a>)

      I18n.t('log_transactions.purchased_recorded_session_with_system_credit', **data)

    when Types::PURCHASED_RECORDING
      data[:session_link] =
        %(<a target="_blank" href="#{abstract_session.absolute_path}">#{abstract_session.always_present_title}</a>)

      if data.key?(:credit_card_number)
        "Purchased Recording for #{data[:session_link]} with %{credit_card_number}"
      elsif data.key?(:paypal_payer_email)
        I18n.t('log_transactions.purchased_recorded_session_with_paypal', **data)
      else
        data.inspect

        # raise "can not interpret #{data.inspect}"
      end
    when Types::PURCHASED_RECORDING_VIA_SYSTEM_CREDIT
      data[:session_link] =
        %(<a target="_blank" href="#{abstract_session.absolute_path}">#{abstract_session.always_present_title}</a>)

      "Purchased Recording for #{data[:session_link]} with system credit"
    when Types::PAID_FOR_CO_PRESENTER
      presenter = Presenter.find(data[:presenter_id])
      data[:name] = presenter.user.public_display_name ? presenter.user.public_display_name : presenter.email
      I18n.t('log_transactions.paid_for_co_presenter', **data)
    when Types::SYSTEM_CREDIT_REFUND
      I18n.t('log_transactions.system_credit_refund', credit_was: number_to_currency(data[:credit_was]),
                                                      credit: number_to_currency(data[:credit]))

    when Types::BOO_BOO_CSR_REFUND
      I18n.t('log_transactions.boo_boo_csr_refund', service_name: Rails.application.credentials.global[:service_name])
    when Types::MONEY_CSR_REFUND
      # NOTE: - for certain log transactions abstract_session could be nil(like credit replenishment kind of transactions)
      I18n.t('log_transactions.money_csr_refund',
             original_transaction_amount: number_to_currency(data[:original_transaction_amount]), service_name: Rails.application.credentials.global[:service_name])

    when Types::MONEY_REFUND
      data[:transaction_id] ||= data[:payment_transaction_id]
      data[:status] ||= 'Success'
      if data.key?(:credit_card_number)
        I18n.t('log_transactions.money_refund_via_credit_card', **data)
      elsif data.key?(:paypal_email)
        I18n.t('log_transactions.money_refund_via_paypal', **data)
      else
        data.inspect
        # raise "can not interpret #{data.inspect}"
      end
    when Types::LIVE_OPT_OUT_FROM_ABSTRACT_SESSION_AFTER_PAYING
      data[:abstract_session_link] =
        %(<a target="_blank" href="#{abstract_session.absolute_path}">#{abstract_session.always_present_title}</a>)
      I18n.t('log_transactions.live_opt_out_from_abstract_session_after_paying', **data)
    when Types::VOD_OPT_OUT_FROM_SESSION_AFTER_PAYING
      data[:abstract_session_link] =
        %(<a target="_blank" href="#{abstract_session.absolute_path}">#{abstract_session.always_present_title}</a>)
      I18n.t('log_transactions.vod_opt_out_from_session_after_paying', **data)
    when Types::CREDIT_REPLENISHMENT

      if data.key?(:credit_card_number)
        I18n.t('log_transactions.credit_replenishment_with_credit_card', **data)
      elsif data.key?(:paypal_payer_email)
        I18n.t('log_transactions.credit_replenishment_with_paypal', **data)
      else
        data.inspect

        # raise "can not interpret #{data.inspect}"
      end

    else
      raise "can not interpret #{type}"
    end + (data[:refund] ? ' (Refund)' : '').to_s
  end

  def is_subscription?
    [LogTransaction::Types::PURCHASED_CHANNEL_SUBSCRIPTION,
     LogTransaction::Types::PURCHASED_CHANNEL_GIFT_SUBSCRIPTION].include?(type)
  end

  def subscription
    return nil unless is_subscription?

    @subscription ||= StripeDb::Subscription.find_by(stripe_id: data[:subscription_stripe_id])
  end

  def amount_cents
    (amount.to_f * 100).to_i
  end

  private

  def notify_user
    case type
    when LogTransaction::Types::PURCHASED_CHANNEL_SUBSCRIPTION
      SubscriptionMailer.channel_subscription_receipt(id).deliver_later
    when LogTransaction::Types::PURCHASED_CHANNEL_GIFT_SUBSCRIPTION
      SubscriptionMailer.gift_subscription(id).deliver_later
      SubscriptionMailer.you_received_gift_subscription(id, subscription&.user&.id).deliver_later
    when LogTransaction::Types::PURCHASED_SERVICE_SUBSCRIPTION
      ServiceSubscriptionsMailer.receipt(id).deliver_later
    end
  end

  def create_reports
    return true unless payment_transaction_type == 'PaymentTransaction'

    pt = payment_transaction
    if pt && PaymentTransaction::Statuses::SUCCESS.include?(pt.status) && pt.purchased_item_type != 'StripeDb::ServicePlan'
      ReportJobs::V1::RevenueOrganization.perform_async(pt.id, 'PaymentTransaction')
      ReportJobs::V1::ReportPurchasedItem.perform_async(pt.id, 'PaymentTransaction')
    end
  end
end
