# frozen_string_literal: true
class Partner
  class Subscription < ::Partner::ApplicationRecord
    enum status: {
      active: 0,
      inactive: 1
    }

    belongs_to :partner_plan, class_name: 'Partner::Plan', inverse_of: :partner_subscriptions, optional: false
    belongs_to :free_subscription, optional: false

    has_one :free_plan, through: :partner_plan
    has_one :organization, through: :free_plan
    has_one :channel, through: :free_plan
    has_one :user, through: :free_subscription

    validates :foreign_customer_id, :foreign_customer_email, :foreign_subscription_id, presence: true

    before_validation :sanitize_customer_email, if: :foreign_customer_email_changed?

    after_commit :set_stopped_at, if: :saved_change_to_status?
    after_commit :set_free_subscription_stopped_at, if: :saved_change_to_stopped_at?

    delegate :replays, :uploads, :livestreams, :interactives, :documents, :im_channel_conversation, to: :free_plan
    delegate :user_id, :start_at, :end_at, :starts_at, to: :free_subscription
    delegate :id, to: :channel, prefix: true

    private

    def sanitize_customer_email
      self.foreign_customer_email = foreign_customer_email.to_s.downcase
    end

    def set_stopped_at
      if inactive?
        update(stopped_at: Time.now.utc) if stopped_at.blank?
      else
        update(stopped_at: nil)
      end
    end

    def set_free_subscription_stopped_at
      free_subscription.update(stopped_at: stopped_at)
    end
  end
end
