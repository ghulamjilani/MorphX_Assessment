# frozen_string_literal: true
class FreeSubscription < ApplicationRecord
  belongs_to :user, optional: false, touch: true
  belongs_to :free_plan, optional: false, touch: true

  has_one :partner_subscription, class_name: 'Partner::Subscription', dependent: :destroy
  has_one :channel, through: :free_plan
  has_one :organization, through: :channel

  delegate :duration_type, to: :free_plan, allow_nil: true
  delegate :duration_in_months, to: :free_plan, allow_nil: true
  delegate :replays, :uploads, :livestreams, :interactives, :documents, :im_channel_conversation, to: :free_plan
  after_commit :subscription_created_notification, on: :create
  after_commit :schedule_subscription_end, if: :saved_change_to_end_at?
  after_commit :subscription_ended_notification, if: :saved_change_to_stopped_at?

  scope :not_stopped, -> { where(stopped_at: nil) }
  scope :in_action, lambda {
    not_stopped.where('(free_subscriptions.end_at IS NULL OR free_subscriptions.end_at > :time_now) AND (free_subscriptions.start_at IS NULL OR free_subscriptions.start_at < :time_now)', time_now: Time.now.utc.to_fs(:db))
  }

  scope :with_features, lambda { |*enabled_features|
    free_plan_where = Array(enabled_features).index_with(true)
    joins(:free_plan).where(free_plans: free_plan_where)
  }

  def user_email=(email)
    self.user_id = User.where(email: email.downcase).pick(:id)
  end

  delegate :email, to: :user, prefix: true, allow_nil: true
  delegate :replays, :uploads, :livestreams, :interactives, :documents, :im_channel_conversation, to: :free_plan, allow_nil: false
  delegate :id, to: :channel, prefix: true, allow_nil: false

  def starts_at
    start_at || created_at
  end

  private

  def subscription_created_notification
    FreeSubscriptionsMailer.invite(id).deliver_later
  end

  def schedule_subscription_end
    return if end_at.blank?

    SidekiqSystem::Schedule.remove(FreeSubscriptions::Cancel, id)
    FreeSubscriptions::Cancel.perform_at(end_at, id)

    # FreeSubscriptionsMailer.going_to_be_finished(id).deliver_later(wait_until: end_at - 1.week)
  end

  def subscription_ended_notification
    return if stopped_at.blank?

    FreeSubscriptionsMailer.ended(id).deliver_later
  end
end
