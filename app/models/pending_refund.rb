# frozen_string_literal: true
class PendingRefund < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  # TODO: polymorphic?
  belongs_to :user
  # belongs_to :braintree_transaction
  belongs_to :payment_transaction

  validate :payment_method_presence
  validates :user_id, presence: true

  def abstract_session
    @abstract_session ||= payment_transaction.purchased_item
  end

  def amount
    @amount ||= payment_transaction.amount
  end

  # NOTE: - there are 3 methods for mailer delivery because
  # save_and_notify_about_reason_other_than_updated_start_at & pending_refund_caused_by_updated_start_at despite both being
  # pending refunds, they have different content and links
  def save_and_notify_about_updated_start_at!(model)
    save!
    Mailer.pending_refund_caused_by_updated_start_at(id, model).deliver_later
  end

  # for readability
  def save_and_notify_about_cancelled_abstract_session!
    save_and_notify_about_reason_other_than_updated_start_at!
  end

  # for readability
  def save_and_notify_after_opting_out!
    save_and_notify_about_reason_other_than_updated_start_at!
  end

  private

  def payment_method_presence
    return if errors.include?(:payment_transaction_id)

    if payment_transaction.blank? && payment_transaction_id.blank?
      errors.add(:payment_transaction_id, 'pending refund need to have payment method reference')
    end
  end

  def save_and_notify_about_reason_other_than_updated_start_at!
    save!
    Mailer.pending_refund_caused_by_reason_other_than_updated_start_at(id).deliver_later
  end
end
