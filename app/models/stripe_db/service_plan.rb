# frozen_string_literal: true
class StripeDb::ServicePlan < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  INTERVALS = {
    day: 'daily',
    month: 'monthly',
    year: 'annual'
  }.freeze

  attr_accessor :push_to_stripe

  alias_attribute :amount_cents, :amount

  belongs_to :plan_package
  has_many :service_subscriptions, class_name: 'StripeDb::ServiceSubscription', foreign_key: :stripe_plan_id
  after_commit :create_or_update_on_stripe, on: :create
  after_commit :create_or_update_on_stripe, if: :push_to_stripe

  scope :active, -> { where(active: true) }
  scope :not_active, -> { where.not(active: true) }

  def create_or_update_on_stripe
    if stripe_id.present?
      Stripe::Plan.update(stripe_id, {
                            active: active,
                            nickname: nickname.presence || plan_package&.name,
                            trial_period_days: trial_period_days.to_i
                          })
    else
      response = Stripe::Plan.create(
        active: active,
        amount: amount,
        interval: interval,
        interval_count: interval_count,
        product: Rails.application.credentials.backend.dig(:initialize, :stripe, :service_product),
        currency: currency || 'usd',
        nickname: nickname.presence || plan_package&.name,
        trial_period_days: trial_period_days.to_i
      )
      update_columns(stripe_id: response.id)
    end
  end

  def update_from_stripe
    if stripe_id.present?
      plan = stripe_object
      update(
        amount: plan.amount,
        interval: plan.interval,
        interval_count: plan.interval_count,
        product: plan.product,
        currency: plan.currency,
        nickname: plan.nickname,
        trial_period_days: plan.trial_period_days
      )
    end
  end

  def stripe_object
    return nil unless stripe_id

    Stripe::Plan.retrieve(stripe_id)
  end

  def interval_type
    INTERVALS[interval.to_sym]
  end

  def formatted_interval
    return unless interval

    [interval_count, interval.capitalize].join(' ')
  end

  def formatted_price
    return unless amount

    Money.new(amount, currency).format
  end

  def type
    'service'
  end

  def always_present_title
    nickname
  end

  def monthly_amount
    case interval
    when 'month'
      amount.to_f / interval_count
    when 'year'
      amount.to_f / interval_count / 12
    when 'day'
      annual_amount / 12
    else
      raise(ActiveRecord::RecordInvalid, 'unknown interval')
    end
  end

  def annual_amount
    case interval
    when 'month'
      (amount.to_f / interval_count) * 12
    when 'year'
      amount.to_f / interval_count
    when 'day'
      (amount.to_f / interval_count) * 365
    else
      raise(ActiveRecord::RecordInvalid, 'unknown interval')
    end
  end

  def money_currency
    @money_currency ||= Money::Currency.find(currency)
  end
end
