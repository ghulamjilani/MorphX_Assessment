# frozen_string_literal: true
class PresenterCreditEntry < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :presenter, touch: true

  validates :amount, numericality: { greater_than: 0 }

  after_create :notify_about_locked_presenter_balance

  private

  def notify_about_locked_presenter_balance
    if presenter.user.presenter_credit_balance < -presenter.credit_line_amount
      csr_recipient_emails.each do |email|
        Mailer.locked_presenter_balance(presenter.id, email).deliver_later
      end
    end
  end
end
