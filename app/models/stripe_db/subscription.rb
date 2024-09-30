# frozen_string_literal: true
# The status of the subscriptions to retrieve.
# One of: incomplete, incomplete_expired, trialing, active, past_due, unpaid, canceled

class StripeDb::Subscription < ActiveRecord::Base
  belongs_to :stripe_plan, class_name: 'StripeDb::Plan'
  belongs_to :user, required: true
  belongs_to :customer_user, class_name: '::User', primary_key: :stripe_customer_id, foreign_key: :customer
  belongs_to :affiliate_everflow_transaction, class_name: 'Affiliate::Everflow::Transaction'
  has_many :affiliate_everflow_tracked_payments, class_name: 'Affiliate::Everflow::TrackedPayment', as: :purchased_item, dependent: :destroy
  has_one :channel_subscription, class_name: '::Subscription', through: :stripe_plan
  has_many :payment_transactions, as: :purchased_item, dependent: :destroy
  has_one :channel, through: :channel_subscription, touch: true
  has_one :organization, through: :channel

  delegate :always_present_title, to: :stripe_plan

  scope :active, -> { where(status: :active) }

  after_create :send_email_to_owner

  def self.create_or_update_from_stripe(sid)
    response = Stripe::Subscription.retrieve(sid)
    object = find_or_initialize_by(stripe_id: response.id)
    plan = StripeDb::Plan.create_or_update_from_stripe(response.plan.id)
    object.stripe_plan_id = plan.id
    object.customer = response.customer
    object.user = if response.metadata && response.metadata[:gift] == 'true'
                    User.find_by(id: response.metadata[:recipient])
                  else
                    User.find_by(stripe_customer_id: response[:customer])
                  end
    object.cancel_at = begin
      DateTime.strptime(response.cancel_at.to_s, '%s')
    rescue StandardError
      nil
    end
    object.canceled_at = begin
      DateTime.strptime(response.canceled_at.to_s, '%s')
    rescue StandardError
      nil
    end
    object.current_period_start = begin
      DateTime.strptime(response.current_period_start.to_s, '%s')
    rescue StandardError
      nil
    end
    object.current_period_end = begin
      DateTime.strptime(response.current_period_end.to_s, '%s')
    rescue StandardError
      nil
    end
    object.start_date = begin
      DateTime.strptime(response.start_date.to_s, '%s')
    rescue StandardError
      nil
    end
    object.trial_start = begin
      DateTime.strptime(response.trial_start.to_s, '%s')
    rescue StandardError
      nil
    end
    object.trial_end = begin
      DateTime.strptime(response.trial_end.to_s, '%s')
    rescue StandardError
      nil
    end
    object.status = response.status
    object.save(validate: false)

    object.send(:create_contact)
    object
  end

  def stripe_item
    @stripe_item ||= Stripe::Subscription.retrieve(stripe_id)
  end

  def type
    stripe_plan.type
  end

  def track_affiliate_transactions
    return unless affiliate_everflow_transaction

    pts = user.payment_transactions.success.where(purchased_item_id: id, purchased_item_type: 'StripeDb::Subscription')
    pts.pluck(:id).each do |pt_id|
      ::Affiliate::Everflow::TrackPaymentTransactionJob.perform_async(pt_id, affiliate_everflow_transaction_id)
    end
  end

  private

  def create_contact
    return unless stripe_plan&.channel_subscription&.user
    return unless user

    contact = Contact.find_or_create_by(for_user: stripe_plan&.channel_subscription&.user, contact_user: user,
                                        email: user.email, name: user.public_display_name)
    contact_status = case status
                     when 'trialing'
                       :trial
                     when 'active'
                       :subscription
                     when 'canceled'
                       :canceled
                     else
                       :unpaid
                     end
    contact.status = contact_status
    contact.save
    user.follow(stripe_plan&.channel_subscription&.user)
  end

  def send_email_to_owner
    SubscriptionMailer.channel_subscribed(id).deliver_later
  end
end
