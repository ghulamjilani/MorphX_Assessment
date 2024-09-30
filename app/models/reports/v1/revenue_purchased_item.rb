# frozen_string_literal: true

# type
# immersive_access
# livestream_access
# recorded
# recording
# channel_subscription

module Reports
  module V1
    class RevenuePurchasedItem
      include ::Mongoid::Document
      store_in collection: 'reports_v1_revenue_purchased_item'

      field :organization_id, type: Integer
      field :channel_id, type: Integer
      field :date, type: Date
      field :purchased_item_id, type: Integer
      field :purchased_item_type, type: String
      field :type, type: String

      field :cost, type: Integer
      field :qty, type: Integer
      field :gross_income, type: Integer
      field :commission, type: Integer
      field :income, type: Integer
      field :refund, type: Integer
      field :refund_system, type: Integer
      field :refund_creator, type: Integer
      field :total, type: Integer

      field :active_at, type: DateTime

      index({ organization_id: 1, channel_id: 1, date: 1, purchased_item_type: 1, purchased_item_id: 1, type: 1 }, { unique: true })
      index({ total: 1 })
      validates :organization_id, :channel_id, :date, :purchased_item_type, :purchased_item_id, :type, presence: true

      FORMATTED_TYPES = {
        immersive_access: 'PPV Interactive',
        livestream_access: 'PPV Livestream',
        recorded: 'PPV Replay',
        recording: 'PPV Upload',
        channel_subscription: 'Subscription',
        booking: 'Booking',
        document: 'Document'
      }.freeze

      def purchased_item
        @purchased_item ||= purchased_item_type.constantize.find_by(id: purchased_item_id)
      end

      def self.organization_ids
        collection.aggregate([{ '$group': { _id: { organization_id: '$organization_id' } } }])
                  .map { |h| h[:_id][:organization_id] }
      end

      def self.group_by_period(filters = {})
        filter = {}
        if filters[:date_from].present? && filters[:date_to].present?
          filter[:date] = { '$gte': filters[:date_from], '$lte': filters[:date_to] }
        elsif filters[:date_from].present?
          filter[:date] = { '$gte': filters[:date_from] }
        elsif filters[:date_to].present?
          filter[:date] = { '$lte': filters[:date_to] }
        end
        filter[:organization_id] = { '$in': filters[:organization_ids].map(&:to_i) } if filters[:organization_ids].present?
        filter[:channel_id] = { '$in': filters[:channel_ids].map(&:to_i) } if filters[:channel_ids].present?
        collection.aggregate([
                               {
                                 '$match': filter
                               }, {
                                 '$group': {
                                   _id: {
                                     organization_id: '$organization_id',
                                     channel_id: '$channel_id',
                                     purchased_item_id: '$purchased_item_id',
                                     purchased_item_type: '$purchased_item_type',
                                     type: '$type', # interactive, livestream, subscription, etc
                                     cost: '$cost' # in case if Session, Video, Recording price was changed
                                   },
                                   qty: { '$sum': '$qty' },
                                   gross_income: { '$sum': '$gross_income' },
                                   commission: { '$sum': '$commission' },
                                   income: { '$sum': '$income' },
                                   refund: { '$sum': '$refund' },
                                   refund_system: { '$sum': '$refund_system' },
                                   refund_creator: { '$sum': '$refund_creator' },
                                   total: { '$sum': '$total' }
                                 }
                               },
                               { '$sort': { '_id.channel_id': 1 } }
                             ])
      end

      def calculate!
        raise 'Please set date/organization/channel/purchased_item/type before' if date.nil? || organization_id.nil? || channel_id.nil? || purchased_item_id.nil? || purchased_item_type.nil? || type.nil?
        raise "Can't find purchased item: #{purchased_item_id} #{purchased_item_type}" if purchased_item.blank?

        cost = case type
               when 'immersive_access'
                 (purchased_item.immersive_access_cost.to_f * 100).to_i
               when 'livestream_access'
                 (purchased_item.livestream_access_cost.to_f * 100).to_i
               when 'recorded'
                 (purchased_item.session.recorded_access_cost.to_f * 100).to_i
               when 'recording', 'document'
                 (purchased_item.purchase_price.to_f * 100).to_i
               when 'channel_subscription'
                 purchased_item.amount_cents
               when 'booking'
                 purchased_item.price_cents
               end

        transactions = case type
                       when 'immersive_access', 'livestream_access', 'recording', 'booking', 'document'
                         PaymentTransaction.where(created_at: date.all_day,
                                                  purchased_item_id: purchased_item_id,
                                                  purchased_item_type: purchased_item_type,
                                                  type: type)
                       when 'recorded'
                         video = Video.find(purchased_item_id)
                         PaymentTransaction.where(created_at: date.all_day,
                                                  purchased_item_id: video.session.id,
                                                  purchased_item_type: 'Session',
                                                  type: type)
                       when 'channel_subscription'
                         PaymentTransaction.joins('LEFT JOIN stripe_subscriptions ON stripe_subscriptions.id = payment_transactions.purchased_item_id')
                                           .where(stripe_subscriptions: { stripe_plan_id: purchased_item_id },
                                                  created_at: date.all_day,
                                                  purchased_item_type: 'StripeDb::Subscription',
                                                  type: [type, 'channel_gift_subscription'])
                       end

        case type
        when 'immersive_access', 'livestream_access', 'recording', 'booking', 'document'
          lts = LogTransaction.joins("LEFT JOIN payment_transactions ON payment_transactions.id = log_transactions.payment_transaction_id AND log_transactions.payment_transaction_type = 'PaymentTransaction'")
                              .where(payment_transactions: { type: type,
                                                             purchased_item_id: purchased_item_id,
                                                             purchased_item_type: purchased_item_type },
                                     created_at: date.all_day)
          income_amount = lts.where("log_transactions.type = 'net_income' AND log_transactions.amount > 0").sum(&:amount_cents).to_i
          commission_amount = lts.where("log_transactions.type = 'net_income' AND log_transactions.amount > 0").map(&:payment_transaction).sum(&:amount).to_i - income_amount
          refund_amount = lts.where(type: 'money_refund').sum(&:amount_cents).to_i
          refund_creator_amount = lts.where("log_transactions.type = 'net_income' AND log_transactions.amount < 0").sum(&:amount_cents).to_i.abs
          refund_system_amount = refund_amount - refund_creator_amount
          total_amount = lts.where(type: 'net_income').sum(&:amount_cents).to_i
        when 'recorded'
          video = Video.find(purchased_item_id)
          lts = LogTransaction.joins("LEFT JOIN payment_transactions ON payment_transactions.id = log_transactions.payment_transaction_id AND log_transactions.payment_transaction_type = 'PaymentTransaction'")
                              .where(payment_transactions: { type: type,
                                                             purchased_item_id: video.session.id,
                                                             purchased_item_type: 'Session' },
                                     created_at: date.all_day)
          income_amount = lts.where("log_transactions.type = 'net_income' AND log_transactions.amount > 0").sum(&:amount_cents).to_i
          commission_amount = lts.where("log_transactions.type = 'net_income' AND log_transactions.amount > 0").map(&:payment_transaction).sum(&:amount).to_i - income_amount
          refund_amount = lts.where(type: 'money_refund').sum(&:amount_cents).to_i
          refund_creator_amount = lts.where("log_transactions.type = 'net_income' AND log_transactions.amount < 0").sum(&:amount_cents).to_i.abs
          refund_system_amount = refund_amount - refund_creator_amount
          total_amount = lts.where(type: 'net_income').sum(&:amount_cents).to_i
        when 'channel_subscription'
          lts = LogTransaction.joins("LEFT JOIN payment_transactions ON payment_transactions.id = log_transactions.payment_transaction_id AND log_transactions.payment_transaction_type = 'PaymentTransaction'")
                              .where(payment_transactions: { type: %w[channel_subscription channel_gift_subscription],
                                                             purchased_item_type: 'StripeDb::Subscription' },
                                     abstract_session_id: purchased_item_id,
                                     abstract_session_type: 'StripeDb::Plan',
                                     created_at: date.all_day)
          income_amount = lts.where("log_transactions.type IN ('sold_channel_subscription', 'sold_channel_gift_subscription') AND log_transactions.amount > 0").sum(&:amount_cents).to_i
          commission_amount = lts.where("log_transactions.type IN ('sold_channel_subscription', 'sold_channel_gift_subscription') AND log_transactions.amount > 0").map(&:payment_transaction).sum(&:amount).to_i - income_amount
          refund_amount = lts.where(type: 'money_refund').sum(&:amount_cents).to_i
          refund_creator_amount = lts.where("log_transactions.type IN ('sold_channel_subscription', 'sold_channel_gift_subscription') AND log_transactions.amount < 0").sum(&:amount_cents).to_i.abs
          refund_system_amount = refund_amount - refund_creator_amount
          total_amount = lts.where(type: %w[sold_channel_subscription sold_channel_gift_subscription]).sum(&:amount_cents).to_i
        end

        self.cost = cost
        self.qty = transactions&.pluck(:id)&.compact&.count || 0
        self.gross_income = transactions&.pluck(:amount)&.compact&.sum || 0
        self.commission = commission_amount
        self.income = income_amount
        self.refund = refund_amount
        self.refund_system = refund_system_amount
        self.refund_creator = refund_creator_amount
        self.total = total_amount
        self.active_at = Time.zone.now

        save!
      end
    end
  end
end
