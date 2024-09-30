# frozen_string_literal: true

module Reports
  module V1
    class RevenueOrganization
      include ::Mongoid::Document
      store_in collection: 'reports_v1_revenue_organization'

      field :organization_id,               type: Integer
      field :channel_id,                    type: Integer
      field :date,                          type: Date

      # calculate action
      field :total,                         type: Integer
      field :total_income,                  type: Integer
      field :total_refund,                  type: Integer
      field :total_fee,                     type: Integer

      field :subscriptions_income,          type: Integer
      field :subscriptions_income_count,    type: Integer
      field :subscriptions_income_fee,      type: Integer
      field :subscriptions_refund,          type: Integer
      field :subscriptions_refund_count,    type: Integer

      field :ppv_sessions,                  type: Integer
      field :ppv_sessions_count,            type: Integer
      field :ppv_sessions_fee,              type: Integer
      field :ppv_sessions_refund,           type: Integer
      field :ppv_sessions_refund_count,     type: Integer

      field :ppv_replays,                   type: Integer
      field :ppv_replays_count,             type: Integer
      field :ppv_replays_income_fee,        type: Integer
      field :ppv_replays_refund,            type: Integer
      field :ppv_replays_refund_count,      type: Integer

      field :ppv_uploads,                   type: Integer
      field :ppv_uploads_count,             type: Integer
      field :ppv_uploads_income_fee,        type: Integer
      field :ppv_uploads_refund,            type: Integer
      field :ppv_uploads_refund_count,      type: Integer

      field :ppv_documents,                 type: Integer
      field :ppv_documents_count,           type: Integer
      field :ppv_documents_income_fee,      type: Integer
      field :ppv_documents_refund,          type: Integer
      field :ppv_documents_refund_count,    type: Integer

      field :active_at,                     type: DateTime

      index({ organization_id: 1, channel_id: 1, date: 1 }, { unique: true })
      index({ total: 1 })
      validates :organization_id, :channel_id, :date, presence: true

      before_save :calculate_total

      # def self.group_by(field, format = 'day')
      #   key_op = [['year', '$year'], ['month', '$month'], ['day', '$dayOfMonth']]
      #   key_op = key_op.take(1 + key_op.find_index { |key, op| format == key })
      #   project_date_fields = Hash[*key_op.collect { |key, op| [key, {op => "$date"}] }.flatten]
      #   group_id_fields = Hash[*key_op.collect { |key, op| [key, "$#{key}"] }.flatten]
      #   pipeline = [
      #       {"$project" => {"name" => 1, field => 1}.merge(project_date_fields)},
      #       {
      #           "$group" => {
      #               '_id': group_id_fields,
      #               totalPrice: {'$sum': {'$multiply': ["$#{field}"]}},
      #               'count': {"$sum" => 1}
      #           }
      #       },
      #       {"$sort" => {"count" => -1}}
      #   ]
      #   collection.aggregate(pipeline)
      # end

      # pp Reports::V1::RevenueOrganization.group_by('subscriptions_income', 'day')
      def self.group_by_chart(filter, field, _format = 'day')
        collection.aggregate([
                               {
                                 '$match': filter
                               }, {
                                 '$group': {
                                   _id: {
                                     month: { '$month': '$date' },
                                     day: { '$dayOfMonth': '$date' },
                                     year: { '$year': '$date' }
                                   },
                                   total: { '$sum': { '$multiply': ["$#{field}"] } },
                                   count: { '$sum': 1 }
                                 }
                               }
                             ]).inject({}) do |res, o|
          res.merge!({ Date.new(o.dig('_id', 'year'), o.dig('_id', 'month'),
                                o.dig('_id', 'day')) => begin
                                  o['total'] / 100.0
                                rescue StandardError
                                  0
                                end })
        end
      end

      def calculate
        raise 'Please set date/organization/channel before' if date.nil? || organization_id.nil? || channel_id.nil?

        self.subscriptions_income       = calculate_subscriptions(:inc)
        self.subscriptions_income_count = calculate_subscriptions(:inc_count)
        self.subscriptions_income_fee   = calculate_subscription_income_fee
        self.subscriptions_refund       = calculate_subscriptions(:ref)
        self.subscriptions_refund_count = calculate_subscriptions(:ref_count)

        self.ppv_sessions               = calculate_ppv_session(:inc)
        self.ppv_sessions_count         = calculate_ppv_session(:inc_count)
        self.ppv_sessions_fee           = calculate_ppv_session_fee
        self.ppv_sessions_refund        = calculate_ppv_session(:ref)
        self.ppv_sessions_refund_count  = calculate_ppv_session(:ref_count)

        self.ppv_replays                = calculate_ppv_replays(:inc)
        self.ppv_replays_count          = calculate_ppv_replays(:inc_count)
        self.ppv_replays_income_fee     = calculate_ppv_replays_fee
        self.ppv_replays_refund         = calculate_ppv_replays(:ref)
        self.ppv_replays_refund_count   = calculate_ppv_replays(:ref_count)

        self.ppv_uploads                = calculate_ppv_uploads(:inc)
        self.ppv_uploads_count          = calculate_ppv_uploads(:inc_count)
        self.ppv_uploads_income_fee     = calculate_ppv_uploads_fee
        self.ppv_uploads_refund         = calculate_ppv_uploads(:ref)
        self.ppv_uploads_refund_count   = calculate_ppv_uploads(:ref_count)

        self.ppv_documents              = calculate_ppv_documents(:count)
        self.ppv_documents_count        = calculate_ppv_documents(:inc_count)
        self.ppv_documents_income_fee   = calculate_ppv_documents_fee
        self.ppv_documents_refund       = calculate_ppv_documents(:ref)
        self.ppv_documents_refund_count = calculate_ppv_documents(:ref_count)

        self.active_at                  = Time.now
      end

      def self.most_popular_organizations(date_range: nil, limit: nil)
        date_range ||= (3.month.ago.to_date..Date.today)
        limit ||= 30
        ids = Reports::V1::RevenueOrganization.where(date: date_range).order(total: :desc).pluck(:organization_id).uniq
        Organization.where(id: ids).limit(limit)
      end

      private

      # :sum, :count
      def calculate_subscription_income_fee
        ids = StripeDb::Subscription.joins(stripe_plan: :channel).where(channels: { id: channel_id }).distinct.ids
        sum = PaymentTransaction.where(created_at: date.all_day).where(
          purchased_item_id: ids, purchased_item_type: 'StripeDb::Subscription'
        ).map do |pt|
          pt.log_transactions.sum(:amount)
        end.compact.sum
        (sum * 100).to_i * -1
      end

      # result :inc, :inc_count, :ref, ref_count
      def calculate_subscriptions(result)
        @result_s ||= begin
          ids = StripeDb::Subscription.joins(stripe_plan: :channel).where(channels: { id: channel_id }).distinct.ids
          PaymentTransaction.where(created_at: date.all_day)
                            .where(purchased_item_id: ids, purchased_item_type: 'StripeDb::Subscription')
        end

        case result
        when :inc
          @result_s.success.pluck(:amount).compact.sum
        when :inc_count
          @result_s.success.pluck(:amount).compact.count
        when :ref
          @result_s.refund.pluck(:amount).compact.sum
        when :ref_count
          @result_s.refund.pluck(:amount).compact.count
        end
      end

      # result :inc, :inc_count, :ref, ref_count
      def calculate_ppv_session(result)
        @result_ps ||= PaymentTransaction.live_access.where(created_at: date.all_day)
                                         .where(purchased_item: session_by_date)

        case result
        when :inc
          @result_ps.success.pluck(:amount).compact.sum
        when :inc_count
          @result_ps.success.pluck(:amount).compact.count
        when :ref
          @result_ps.refund.pluck(:amount).compact.sum
        when :ref_count
          @result_ps.refund.pluck(:amount).compact.count
        end
      end

      # :sum, :count
      def calculate_ppv_session_fee
        sum = PaymentTransaction.live_access.success.where(created_at: date.all_day)
                                .where(purchased_item: session_by_date).map do |pt|
          pt.log_transactions.sum(:amount)
        end.compact.sum
        (sum * 100).to_i * -1
      end

      # result :inc, :inc_count, :ref, ref_count
      def calculate_ppv_replays(result)
        @result_pr ||= PaymentTransaction.vod_access.success.where(created_at: date.all_day)
                                         .where(purchased_item: video_by_date)

        case result
        when :inc
          @result_pr.success.pluck(:amount).compact.sum
        when :inc_count
          @result_pr.success.pluck(:amount).compact.count
        when :ref
          @result_pr.refund.pluck(:amount).compact.sum
        when :ref_count
          @result_pr.refund.pluck(:amount).compact.count
        end
      end

      # :sum, :count
      def calculate_ppv_replays_fee
        sum = PaymentTransaction.vod_access.success.where(created_at: date.all_day)
                                .where(purchased_item: video_by_date).map do |pt|
          pt.log_transactions.sum(:amount)
        end.compact.sum
        (sum * 100).to_i * -1
      end

      # result :inc, :inc_count, :ref, ref_count
      def calculate_ppv_uploads(result)
        @result_pu ||= PaymentTransaction.where(created_at: date.all_day)
                                         .where(purchased_item: upload_by_date)

        case result
        when :inc
          @result_pu.success.pluck(:amount).compact.sum
        when :inc_count
          @result_pu.success.pluck(:amount).compact.count
        when :ref
          @result_pu.refund.pluck(:amount).compact.sum
        when :ref_count
          @result_pu.refund.pluck(:amount).compact.count
        end
      end

      def calculate_ppv_documents_fee
        sum = PaymentTransaction.document_access.success.where(created_at: date.all_day)
                                .where(purchased_item: document_by_date).map do |pt|
          pt.log_transactions.sum(:amount)
        end.compact.sum
        (sum * 100).to_i * -1
      end

      # result :inc, :inc_count, :ref, ref_count
      def calculate_ppv_documents(result)
        @result_pu ||= PaymentTransaction.where(created_at: date.all_day)
                                         .where(purchased_item: document_by_date)

        case result
        when :inc
          @result_pu.success.pluck(:amount).compact.sum
        when :inc_count
          @result_pu.success.pluck(:amount).compact.count
        when :ref
          @result_pu.refund.pluck(:amount).compact.sum
        when :ref_count
          @result_pu.refund.pluck(:amount).compact.count
        end
      end

      # :sum, :count
      def calculate_ppv_uploads_fee
        sum = PaymentTransaction.where(created_at: date.all_day)
                                .where(purchased_item: upload_by_date).map do |pt|
          pt.log_transactions.sum(:amount)
        end.compact.sum
        (sum * 100).to_i * -1
      end

      def calculate_total
        self.total_income   = subscriptions_income.to_i      + ppv_sessions.to_i          + ppv_replays.to_i             +  ppv_uploads.to_i
        self.total_fee      = subscriptions_income_fee.to_i  + ppv_sessions_fee.to_i      + ppv_replays_income_fee.to_i  +  ppv_uploads_income_fee.to_i
        self.total_refund   = subscriptions_refund.to_i      + ppv_sessions_refund.to_i   + ppv_replays_refund.to_i      +  ppv_uploads_refund.to_i
        self.total = total_income - total_refund - total_fee
      end

      # helpers

      def session_by_date
        @session_by_date ||= begin
          pids = PaymentTransaction.live_access.success.where(created_at: date.all_day).where(purchased_item_type: 'Session').pluck(:purchased_item_id)
          Session.where(id: pids, channel_id: channel_id)
        end
      end

      def video_by_date
        @video_by_date ||= begin
          pids = PaymentTransaction.vod_access.success.where(created_at: date.all_day).where(purchased_item_type: 'Session').pluck(:purchased_item_id)
          Session.where(id: pids, channel_id: channel_id)
        end
      end

      def upload_by_date
        @upload_by_date ||= begin
          pids = PaymentTransaction.recording_access.success.where(created_at: date.all_day).where(purchased_item_type: 'Recording').pluck(:purchased_item_id)
          Recording.where(id: pids, channel_id: channel_id)
        end
      end

      def document_by_date
        @document_by_date ||= begin
          pids = PaymentTransaction.document_access.success.where(created_at: date.all_day).where(purchased_item_type: 'Document').pluck(:purchased_item_id)
          Document.where(id: pids, channel_id: channel_id)
        end
      end
    end
  end
end
