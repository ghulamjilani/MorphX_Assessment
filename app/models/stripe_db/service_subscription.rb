# frozen_string_literal: true
class StripeDb::ServiceSubscription < ActiveRecord::Base
  has_logidze

  STRIPE_STATUSES = %w[new active past_due unpaid canceled incomplete incomplete_expired trialing].freeze
  SERVICE_STATUSES = %w[new trial trial_suspended active grace suspended pending_deactivation deactivated].freeze
  belongs_to :stripe_plan, class_name: 'StripeDb::ServicePlan'
  belongs_to :organization, touch: true
  belongs_to :user, touch: true
  belongs_to :customer_user, class_name: '::User', primary_key: :stripe_customer_id, foreign_key: :customer
  has_one :plan_package, through: :stripe_plan, source: :plan_package
  belongs_to :affiliate_everflow_transaction, class_name: 'Affiliate::Everflow::Transaction'
  has_many :affiliate_everflow_tracked_payments, class_name: 'Affiliate::Everflow::TrackedPayment', as: :purchased_item, dependent: :destroy
  has_many :feature_parameters, through: :plan_package
  has_many :payment_transactions, as: :purchased_item, dependent: :destroy

  delegate :always_present_title, to: :stripe_plan

  validates :status, inclusion: { in: STRIPE_STATUSES }
  validates :service_status, inclusion: { in: SERVICE_STATUSES }
  scope :active_and_trialing, -> { where(service_status: %i[active trial grace trial_suspended]) }

  after_initialize :set_initial_status
  after_create :notify_platform_owner
  after_create :assign_organization
  after_commit :send_cancellation_request, on: :update, if: :saved_change_to_canceled_at?
  after_commit :reindex_user_and_content, on: :update, if: -> { saved_change_to_service_status? && %w[deactivated active].include?(service_status) }

  state_machine :status, initial: :new do
    after_transition new: :trialing do |subscription|
      ServiceSubscriptionsMailer.trial_started(subscription.id).deliver_later
      subscription.trial!
    end
    after_transition past_due: :trialing, &:trial!
    after_transition new: :incomplete, &:suspended!
    after_transition any - %i[new trialing active] => :active, &:activate!
    after_transition any - %i[canceled trialing past_due] => :canceled do |subscription, _transition|
      subscription.deactivate!
    end
    after_transition %i[past_due trialing] => :canceled do |subscription, _transition|
      subscription.deactivate!
    end
    after_transition %i[trialing active] => :past_due do |subscription, transition|
      case transition.from
      when 'trialing'
        subscription.trial_suspended!
      when 'active'
        if subscription.stripe_item.trial_end
          invoices = Stripe::Invoice.list({ subscription: subscription.stripe_id })
          paid = invoices.data.map(&:amount_paid).uniq

          # if first invoice was zero AND all invoices paid is equal to each other AND no invoices was paid
          if invoices.data.last.blank? || (invoices.data.last.amount_due.zero? && paid.size == 1 && paid.first.zero?)
            subscription.trial_suspended!
          else
            subscription.grace!
          end
        else
          subscription.grace!
        end
      end
    end
    after_transition new: :active do |subscription|
      subscription.activate!
      ServiceSubscriptionsMailer.activated(subscription.id).deliver_later
    end
    after_transition trialing: :active do |subscription|
      invoice = Stripe::Invoice.retrieve(subscription.stripe_item.latest_invoice) if subscription.stripe_item.latest_invoice

      if invoice&.paid
        # if latest invoice was paid - activate
        subscription.activate!
      else
        # stay in trialing mode until we receive charge.success webhook or subscription.updated
        subscription.update(status: :trialing)
      end
    end
    event :trialing do
      transition any => :trialing
    end
    event :active do
      transition %i[trialing new unpaid incomplete past_due] => :active
    end
    event :canceled do
      transition any => :canceled
    end
    event :past_due do
      transition any => :past_due
    end
    event :unpaid do
      transition any => :unpaid
    end
    # if the initial payment attempt fails
    event :incomplete do
      transition any => :incomplete
    end
    # If the first invoice is not paid within 23 hours
    event :incomplete_expired do
      transition any => :incomplete_expired
    end
  end

  state_machine :service_status, initial: :new do
    after_transition any => :trial_suspended do |subscription|
      subscription.update(trial_suspended_at: Time.now)
      ServiceSubscriptionsMailer.trial_finished_payment_failed(subscription.id).deliver_later
    end
    after_transition any - :grace => :grace do |subscription|
      subscription.update(grace_at: Time.now)
      ServiceSubscriptionsMailer.grace_started_payment_failed(subscription.id).deliver_later
    end
    after_transition grace: :active do |subscription|
      subscription.update(grace_at: nil)
    end
    after_transition any - :suspended => :suspended do |subscription|
      subscription.update(suspended_at: Time.now)
      ServiceSubscriptionsMailer.suspended_started(subscription.id).deliver_later
    end
    after_transition suspended: :active do |subscription|
      subscription.update(grace_at: nil, suspended_at: nil)
    end
    after_transition trial_suspended: %i[active trial] do |subscription|
      subscription.update(trial_suspended_at: nil)
    end
    after_transition trial: :deactivated do |subscription|
      # cancel subscription on stripe
      subscription.stripe_item.delete
    rescue StandardError
      nil
    ensure
      ServiceSubscriptionsMailer.trial_ended(subscription.id).deliver_later
      ServiceSubscriptionJobs::CancelUnacceptedInvitationsJob.perform_async(subscription.id) if subscription.user.organization.blank? || !subscription.user.organization&.split_revenue_plan
    end
    after_transition trial_suspended: :deactivated do |subscription|
      # cancel subscription on stripe
      subscription.stripe_item.delete
    rescue StandardError
      nil
    ensure
      ServiceSubscriptionsMailer.trial_suspended_ended(subscription.id).deliver_later
      ServiceSubscriptionJobs::CancelUnacceptedInvitationsJob.perform_async(subscription.id) if subscription.user.organization.blank? || !subscription.user.organization&.split_revenue_plan
    end
    after_transition any - %i[trial trial_suspended] => :deactivated do |subscription|
      # cancel subscription on stripe
      subscription.stripe_item.delete
    rescue StandardError
      nil
    ensure
      ServiceSubscriptionsMailer.deactivated(subscription.id).deliver_later
      ServiceSubscriptionJobs::CancelUnacceptedInvitationsJob.perform_async(subscription.id) if subscription.user.organization.blank? || !subscription.user.organization&.split_revenue_plan
    end
    event :trial do
      transition any => :trial
    end
    event :trial_suspended do
      transition %i[active trial] => :trial_suspended
    end
    event :activate do
      transition any => :active
    end
    event :grace do
      transition active: :grace
    end
    event :suspended do
      transition %i[new grace] => :suspended
    end
    event :pending_deactivation do
      transition any => :pending_deactivation
    end
    event :deactivate do
      transition any => :deactivated
    end
  end

  def self.create_or_update_from_stripe(sid)
    response = Stripe::Subscription.retrieve(sid)
    object = find_or_initialize_by(stripe_id: response.id)
    object.transaction do
      plan = StripeDb::ServicePlan.find_by(stripe_id: response.plan.id)
      object.stripe_plan_id = plan.id
      object.customer ||= response.customer
      object.user ||= User.find_by(stripe_customer_id: response[:customer])
      object.organization_id ||= object.user.organization&.id
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
      object.save
      object.send(:"#{response.status}!") if response.status != object.status
    end
    object
  end

  def canceled?
    status != :canceled
  end

  def stripe_item
    Stripe::Subscription.retrieve(stripe_id)
  end

  def feature_value(code)
    feature_parameters.by_code(code).pick(:value)
  end

  def track_affiliate_transactions
    return unless affiliate_everflow_transaction

    pts = user.payment_transactions.success.where(purchased_item_id: id, purchased_item_type: 'StripeDb::ServiceSubscription')
    pts.pluck(:id).each do |pt_id|
      ::Affiliate::Everflow::TrackPaymentTransactionJob.perform_async(pt_id, affiliate_everflow_transaction_id)
    end
  end

  def change_plan!(plan_id)
    plan = StripeDb::ServicePlan.joins(:plan_package).active.where(plan_packages: { active: true }).find(plan_id)
    params = {
      cancel_at_period_end: false,
      proration_behavior: 'always_invoice',
      payment_behavior: 'error_if_incomplete',
      items: [{ id: stripe_item.items.data[0].id, price: plan.stripe_id }]
    }
    Stripe::Subscription.update(stripe_item.id, params)
  end

  private

  def set_initial_status
    self.status ||= :new
    self.service_status ||= :new
  end

  def send_cancellation_request
    if canceled_at.present? && status == 'active'
      ServiceSubscriptionsMailer.cancellation_requested(id).deliver_later
    end
  end

  def reindex_user_and_content
    user.update_pg_search_models if user.present?
  end

  def notify_platform_owner
    ServiceSubscriptionsMailer.notify_platform_owner(id).deliver_later
  end

  def assign_organization
    update(organization_id: user.organization.id) if user.organization.present?
  end
end
