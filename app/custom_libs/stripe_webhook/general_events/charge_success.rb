# frozen_string_literal: true

class StripeWebhook::GeneralEvents::ChargeSuccess < StripeWebhook::Base
  @event_type = 'charge.succeeded'

  def perform
    charge = @event.data.object

    if PaymentTransaction.exists?(provider: :stripe, pid: charge.id)
      @logger.info("Charge ##{charge.id} has been already processed. Event ##{@event.id}")
      return
    end
    customer = User.find_by(stripe_customer_id: charge.customer)
    unless customer
      @logger.info("Stripe webhook error: User not found. Charge ##{charge.id}. Event ##{@event.id}")
      return
    end

    source = charge.source
    transaction = Stripe::BalanceTransaction.retrieve(charge.balance_transaction)
    invoice = Stripe::Invoice.retrieve(charge.invoice)

    if invoice.subscription
      stripe_subscription = Stripe::Subscription.retrieve(invoice.subscription)
      subscription = StripeDb::Subscription.find_by(stripe_id: stripe_subscription.id) || StripeDb::ServiceSubscription.find_by(stripe_id: stripe_subscription.id)
      unless subscription
        @logger.info("Stripe Subscription does not exist', parameters: #{@event.to_json}")
        return
      end
      if subscription.is_a?(StripeDb::ServiceSubscription)
        # call update because if subscription was trialing it becomes active in all cases
        # charge goes next and only after charge status can be changed to past_due if it failed
        # check app/models/stripe_db/service_subscription.rb
        # after_transition trialing: :active ...
        StripeDb::ServiceSubscription.create_or_update_from_stripe(subscription.stripe_id)
        # load actual plan from Stripe because subscription plan update will fire after charge success
        plan = StripeDb::ServicePlan.find_by(stripe_id: invoice.lines.data.last.plan.id)
      else
        plan = subscription.stripe_plan
      end
      pt_type = if plan.type == 'channel'
                  if stripe_subscription.metadata && stripe_subscription.metadata[:gift] == 'true'
                    TransactionTypes::CHANNEL_GIFT_SUBSCRIPTION
                  else
                    TransactionTypes::CHANNEL_SUBSCRIPTION
                  end
                else
                  TransactionTypes::SERVICE_SUBSCRIPTION
                end

      payment_transaction = PaymentTransaction.new(provider: :stripe)
      payment_transaction.amount = charge.amount
      payment_transaction.amount_currency = charge.currency
      payment_transaction.type = pt_type
      payment_transaction.user = customer
      payment_transaction.purchased_item = subscription
      payment_transaction.pid = charge.id
      payment_transaction.status = charge.status
      if source
        payment_transaction.country = source.address_country
        payment_transaction.zip = source.address_zip
        payment_transaction.name_on_card = source.name
      end
      payment_transaction.tax_cents = invoice.tax.to_i
      payment_transaction.checked_at = Time.at(charge.created)

      if source
        payment_transaction.credit_card_last_4 = source.last4
        payment_transaction.card_type = source.brand
      end
      payment_transaction.save(validate: false)

      if subscription.is_a?(StripeDb::ServiceSubscription) || subscription.is_a?(StripeDb::Subscription)
        payment_transaction.track_affiliate_transaction
      end

      data = if payment_transaction.credit_card?
               { credit_card_number: ('*' * 12) + payment_transaction.credit_card_last_4.to_s,
                 card_type: payment_transaction.card_type, charge_id: charge.id }
             else
               { stripe_customer: customer.stripe_customer_id, charge_id: charge.id }
             end
      data[:subscription_stripe_id] = subscription.stripe_id
      if stripe_subscription.metadata && stripe_subscription.metadata[:gift] == 'true'
        data[:gift] = true
        @recipient = User.find_by(id: stripe_subscription.metadata[:recipient])
        data[:user_name] = @recipient.public_display_name
        data[:user_id] = @recipient.id
      else
        data[:gift] = false
      end
      lt_type = if plan.type == 'channel'
                  if stripe_subscription.metadata && stripe_subscription.metadata[:gift] == 'true'
                    LogTransaction::Types::PURCHASED_CHANNEL_GIFT_SUBSCRIPTION
                  else
                    LogTransaction::Types::PURCHASED_CHANNEL_SUBSCRIPTION
                  end
                else
                  LogTransaction::Types::PURCHASED_SERVICE_SUBSCRIPTION
                end
      customer.log_transactions.create!(type: lt_type,
                                        abstract_session: plan,
                                        image_url: payment_transaction.image_url,
                                        data: data,
                                        amount: -payment_transaction.total_amount / 100.0,
                                        payment_transaction: payment_transaction)
      if plan.type == 'channel'
        plan_owner = plan.channel_subscription.user
        revenue_split = plan_owner.revenue_percent / 100.0

        plt_type = if stripe_subscription.metadata && stripe_subscription.metadata[:gift] == 'true'
                     LogTransaction::Types::SOLD_CHANNEL_GIFT_SUBSCRIPTION
                   else
                     LogTransaction::Types::SOLD_CHANNEL_SUBSCRIPTION
                   end
        # create log transaction for channel's owner
        # available on owner's dashboard
        plan_owner.log_transactions.create!(type: plt_type,
                                            abstract_session: plan,
                                            image_url: payment_transaction.image_url,
                                            data: data,
                                            amount: payment_transaction.amount * revenue_split / 100.0,
                                            payment_transaction: payment_transaction)

        entry = Plutus::Entry.new(
          description: "Sold Channel Subscription - Plan: #{plan.im_name} - Charge: #{charge.id}",
          commercial_document: payment_transaction,
          debits: [
            { account_name: Accounts::Asset::MERCHANT, amount: (payment_transaction.total_amount / 100.0).round(2) },
            { account_name: Accounts::COGS::VENDOR_EARNINGS,
              amount: (payment_transaction.amount * revenue_split / 100.0).round(2) }
          ],
          credits: [
            { account_name: Accounts::Income::SUBSCRIPTION_REVENUE,
              amount: ((payment_transaction.amount / 100.0) - (transaction.fee / 100.0)).round(2) },
            { account_name: Accounts::Income::MISCELLANEOUS_FEES, amount: (transaction.fee / 100.0).round(2) },
            { account_name: Accounts::ShortTermLiability::SALES_TAX,
              amount: (payment_transaction.tax_cents.to_i / 100.0).round(2) },
            { account_name: Accounts::ShortTermLiability::VENDOR_PAYABLE,
              amount: (payment_transaction.amount * revenue_split / 100.0).round(2) }
          ]
        )
        entry.save!
      else
        entry = Plutus::Entry.new(
          description: "Sold Service Subscription - Plan: #{plan.im_name} - Charge: #{charge.id}",
          commercial_document: payment_transaction,
          debits: [
            { account_name: Accounts::Asset::MERCHANT, amount: (payment_transaction.total_amount / 100.0).round(2) }
          ],
          credits: [
            { account_name: Accounts::Income::SAAS_REVENUE,
              amount: ((payment_transaction.amount / 100.0) - (transaction.fee / 100.0)).round(2) },
            { account_name: Accounts::Income::MISCELLANEOUS_FEES, amount: (transaction.fee / 100.0).round(2) },
            { account_name: Accounts::ShortTermLiability::SALES_TAX,
              amount: (payment_transaction.tax_cents.to_i / 100.0).round(2) }
          ]
        )
        entry.save!
      end
    end
  end
end
