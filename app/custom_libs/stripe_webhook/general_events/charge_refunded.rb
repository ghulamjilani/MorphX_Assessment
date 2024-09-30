# frozen_string_literal: true

class StripeWebhook::GeneralEvents::ChargeRefunded < StripeWebhook::Base
  @event_type = 'charge.refunded'

  def perform
    charge = @event.data.object

    @pt = PaymentTransaction.find_by(provider: :stripe, pid: charge.id)

    return unless @pt
    return if @pt.status == 'refund'

    @pt.status = charge.refunded ? PaymentTransaction::Statuses::REFUND : charge.status
    @pt.save!

    charge.refunds.data.each do |refund|
      begin
        Refund.create!(payment_transaction_id: @pt.id, pid: refund.id, provider: :stripe)
      rescue StandardError
        next
      end

      refund_amount = refund.amount
      data = {
        transaction_id: @pt.pid,
        status: charge.status,
        refund_id: refund.id,
        credit_card_number: ('*' * 12) + @pt.credit_card_last_4.to_s,
        refund: true
      }

      buyer_lt = @pt.user.log_transactions.find_or_create_by(type: LogTransaction::Types::MONEY_REFUND,
                                                             abstract_session: @pt.purchased_item,
                                                             data: data,
                                                             amount: refund_amount / 100.0,
                                                             payment_transaction: @pt)

      case @pt.purchased_item
      when Session
        if purchased_item.finished?
          creator = @pt.purchased_item.presenter.user
          creator.log_transactions.find_or_create_by!(type: LogTransaction::Types::NET_INCOME,
                                                      abstract_session: @pt.purchased_item,
                                                      data: data,
                                                      amount: (-refund_amount / 100.0 * creator.revenue_percent) / 100.0,
                                                      payment_transaction: @pt)
        end
      when Recording
        creator = @pt.purchased_item.channel.organizer
        creator.log_transactions.find_or_create_by!(type: LogTransaction::Types::NET_INCOME,
                                                    abstract_session: @pt.purchased_item,
                                                    data: data,
                                                    amount: (-refund_amount / 100.0 * creator.revenue_percent) / 100.0,
                                                    payment_transaction: @pt)
      when StripeDb::Plan
        # total_amount includes tax, so for refunding(-) from creator we need to exclude it
        # because incoming(+) transaction doesn't include it
        creator_refund_amount = ((refund_amount == @pt.total_amount) ? @pt.amount : refund_amount).to_i
        creator = @pt.purchased_item.channel_subscription.channel.organizer
        creator.log_transactions.find_or_create_by!(type: LogTransaction::Types::SOLD_CHANNEL_SUBSCRIPTION,
                                                    abstract_session: @pt.purchased_item,
                                                    data: data,
                                                    amount: (-creator_refund_amount / 100.0 * creator.revenue_percent) / 100.0,
                                                    payment_transaction: @pt)
      when StripeDb::ServicePlan
        # total_amount includes tax, so for refunding(-) from creator we need to exclude it
        # because incoming(+) transaction doesn't include it
        creator = @pt.purchased_item.channel_subscription.channel.organizer
        creator.log_transactions.find_or_create_by!(type: LogTransaction::Types::PURCHASED_SERVICE_SUBSCRIPTION,
                                                    abstract_session: @pt.purchased_item,
                                                    data: data,
                                                    amount: refund_amount / 100.0,
                                                    payment_transaction: @pt)
      end

      entry = Plutus::Entry.new(
        description: "Money refund - #{@pt.purchased_item.always_present_title}",
        commercial_document: @pt,
        debits: [
          { account_name: Accounts::LongTermLiability::CUSTOMER_CREDIT, amount: (refund_amount / 100.0).round(2) }
        ],
        credits: [
          { account_name: Accounts::Asset::MERCHANT, amount: (refund_amount / 100.0).round(2) }
        ]
      )
      entry.save!

      Mailer.money_refund_receipt(@pt.user.id, buyer_lt.id).deliver_later
    end
  end
end
