# frozen_string_literal: true
class FreePlan < ApplicationRecord
  enum duration_type: {
    duration_forever: 0,
    duration_fixed: 1, # apply :duration_in_months
    duration_interval: 2 # between :start_at and :end_at
  }

  belongs_to :channel, class_name: 'Channel', inverse_of: :free_plans, foreign_key: :channel_uuid, primary_key: :uuid, optional: false, touch: true
  has_one :organization, through: :channel
  has_many :free_subscriptions, dependent: :destroy
  has_many :partner_plans, class_name: 'Partner::Plan', dependent: :destroy
  has_many :partner_subscriptions, class_name: 'Partner::Subscription', through: :partner_plans

  before_validation :sanitize_name, if: :name_changed?
  validates :name, presence: true
  validates :duration_in_months, presence: true, if: :duration_fixed?

  after_commit :update_free_subscriptions_duration, if: ->(free_plan) { free_plan.saved_change_to_end_at? || free_plan.saved_change_to_start_at? || free_plan.saved_change_to_duration_type? }
  after_commit :disable_partner_plans, if: :saved_change_to_archived_at?
  delegate :id, to: :channel, prefix: true, allow_nil: false
  delegate :id, to: :organization, prefix: true, allow_nil: false

  scope :not_archived, -> { where(archived_at: nil) }

  alias_attribute :title, :name

  def free_subscription_params
    free_subscription_params = { free_plan_id: id }

    case duration_type
    when 'duration_fixed'
      free_subscription_params[:start_at] = Time.now.utc
      free_subscription_params[:end_at] = duration_in_months.to_i.months.from_now
    when 'duration_interval'
      free_subscription_params[:start_at] = start_at
      free_subscription_params[:end_at] = end_at
    end

    free_subscription_params
  end

  private

  def sanitize_name
    self.name = Sanitize.clean(
      name.to_s.html_safe,
      elements: %w[a b i br s u ul ol li p strong em],
      attributes: { a: %w[href target title] }.with_indifferent_access
    )
  end

  def update_free_subscriptions_duration
    if duration_forever?
      free_subscriptions.update_all(start_at: nil, end_at: nil, updated_at: Time.now.utc)
    elsif duration_interval?
      free_subscriptions.update_all(start_at: start_at, end_at: end_at, updated_at: Time.now.utc)
    end
  end

  def disable_partner_plans
    return if archived_at.blank?

    partner_plans.update_all(enabled: false, updated_at: Time.now.utc)
  end
end
