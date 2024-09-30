# frozen_string_literal: true

class PurchaseReferralFeesAccounting
  def self.perform(session_id, payment_transaction_id, system_credit_entry_id)
    session = Session.find(session_id)

    if payment_transaction_id.blank? && system_credit_entry_id.blank?
      Rails.logger.info 'no actual transaction, skipping referral fee accounting'
      return
    end

    if payment_transaction_id.present?
      payment_transaction = PaymentTransaction.find(payment_transaction_id)

      referral_record = Referral.where(user: payment_transaction.user).last
      # because we don't give bonus referral fee for purchases of master organizer's sessions
      if referral_record.present? && session.organizer != referral_record.master_user
        # amount in cents
        gross_profit = (payment_transaction.amount / 100.0) * (100 - referral_record.master_user.revenue_percent) / 100.0

        commision = gross_profit * referral_record.master_user.referral_participant_fee_in_percent / 100.0

        referral_record.master_user.create_presenter if referral_record.master_user.presenter.blank?
        referral_record.master_user.presenter.issued_presenter_credits.create!(amount: commision,
                                                                               type: IssuedPresenterCredit::Types::REFERRAL_FEE)

        referral_record.master_user.log_transactions.create!(type: LogTransaction::Types::REFERRAL_FEE,
                                                             abstract_session: session,
                                                             data: { display_name: referral_record.user.public_display_name },
                                                             amount: commision,
                                                             payment_transaction: payment_transaction)

        entry = Plutus::Entry.new(
          description: "Referral fee - #{session.always_present_title}",
          commercial_document: referral_record,
          debits: [
            { account_name: Accounts::Expense::PRESENTER_COMMISION, amount: commision }
          ],
          credits: [
            { account_name: Accounts::ShortTermLiability::VENDOR_PAYABLE, amount: commision }
          ]
        )
        entry.save!
      end
    end
  end
end
