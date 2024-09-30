# frozen_string_literal: true
class StripeDb::Plan < ActiveRecord::Base
  belongs_to :channel_subscription, class_name: '::Subscription'
  has_many :stripe_subscriptions, class_name: 'StripeDb::Subscription', foreign_key: :stripe_plan_id
  has_one :channel, through: :channel_subscription, source: :channel
  validates :im_name, presence: true
  # Allowed by stripe %w(day week month year)
  validates :interval, inclusion: { in: %w[day month] }
  validates :interval_count, presence: true

  after_create :create_stripe_plan, if: ->(p) { p.stripe_id.blank? }
  after_update :update_on_stripe, if: :should_be_updated?
  before_destroy :destroy_stripe_plan

  scope :active, -> { where(active: true, im_enabled: true).where.not(stripe_id: nil) }
  def as_json(options)
    hash = {
      stripe_subscriptions_count: stripe_subscriptions.active.count
    }
    super(options).merge(hash)
  end

  def self.create_or_update_from_stripe(sid)
    response = Stripe::Plan.retrieve(sid)
    object = find_or_initialize_by(stripe_id: response.id)
    object.amount = response.amount / 100.0
    object.im_name = response.nickname
    object.im_color ||= '#0000ff'

    object.object = response.object
    object.active = response.active
    object.aggregate_usage = response.aggregate_usage
    object.billing_scheme = response.billing_scheme
    object.created = response.created
    object.currency = response.currency
    object.interval = response.interval
    object.interval_count = response.interval_count
    object.livemode = response.livemode
    object.nickname = response.nickname
    object.product = response.product
    object.tiers_mode = response.tiers_mode
    object.transform_usage = response.transform_usage
    object.trial_period_days = response.trial_period_days
    object.usage_type = response.usage_type
    object.save(validate: false)
    object
  end

  def amount_cents
    (amount.to_f * 100).to_i
  end

  def always_present_title
    im_name
  end

  def type
    @type ||= channel_subscription_id.present? ? 'channel' : 'immerss'
  end

  def title
    if channel_subscription&.channel
      "#{nickname} of #{channel_subscription.channel.title}"
    else
      nickname
    end
  end

  def period
    case interval
    when 'month'
      case interval_count.to_i
      when 1
        'monthly'
      when 3
        'quarterly'
      when 6
        'semi annually'
      when 12
        'annually'
      else
        "#{interval_count} #{interval.capitalize.pluralize(interval_count)}"
      end
    else
      "#{interval_count} #{interval.capitalize.pluralize(interval_count)}"
    end
  end

  def formatted_price
    return unless amount

    Money.new(amount_cents, currency).format
  end

  private

  def should_be_updated?
    stripe_id.present? && (im_name_changed? || trial_period_days_changed? || im_enabled_changed?)
  end

  def update_on_stripe
    begin
      update_params = {}
      update_params[:nickname] = im_name if im_name_changed?
      update_params[:trial_period_days] = trial_period_days.to_i if trial_period_days_changed?
      update_params[:active] = im_enabled if im_enabled_changed?
      response = Stripe::Plan.update(stripe_id, update_params)
    rescue StandardError => e
      Airbrake.notify_sync(RuntimeError.new(e.message), parameters: { plan_id: id })
      Rails.logger.error e.message
      return
    end
    response
  end

  def create_stripe_plan
    begin
      response = Stripe::Plan.create(
        amount: amount_cents,
        interval: interval,
        interval_count: interval_count,
        product: channel_subscription.channel.stripe_id,
        currency: 'usd',
        nickname: im_name,
        trial_period_days: trial_period_days.to_i
      )
    rescue StandardError => e
      Airbrake.notify_sync(RuntimeError.new(e.message), parameters: { plan_id: id })
      Rails.logger.error e.message
      return
    end
    self.stripe_id = response.id
    self.object = response.object
    self.active = response.active
    self.aggregate_usage = response.aggregate_usage
    self.billing_scheme = response.billing_scheme
    self.created = response.created
    self.currency = response.currency
    self.interval = response.interval
    self.interval_count = response.interval_count
    self.livemode = response.livemode
    self.nickname = response.nickname
    self.product = response.product
    self.tiers_mode = response.tiers_mode
    self.transform_usage = response.transform_usage
    self.trial_period_days = response.trial_period_days
    self.usage_type = response.usage_type
    save(validate: false)
  end

  def destroy_stripe_plan
    return unless stripe_id

    begin
      result = stripe_plan.delete
      raise 'Can not delete plan' unless result.deleted
    rescue StandardError => e
      Rails.logger.error e.message
      Airbrake.notify_sync(RuntimeError.new(e.message), parameters: { plan_id: id })
    end
  end

  def stripe_plan
    @stripe_plan ||= Stripe::Plan.retrieve(stripe_id)
  end
end
