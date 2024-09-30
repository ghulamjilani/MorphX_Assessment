# frozen_string_literal: true

ActiveAdmin.register LogTransaction, as: 'TransactionLog' do
  menu parent: 'Ledger'

  actions :all, except: (Rails.env.production? ? [:destroy] : [])
  filter :abstract_session_id
  filter :abstract_session_type
  filter :payment_transaction_id
  filter :payment_transaction_type
  filter :user
  filter :created_at
  filter :updated_at
  filter :amount
  filter :type
  filter :by_data_contains, as: :string, label: 'Data contains'

  collection_action :generate_report do
    params[:reports] ||= {}
    if params[:reports][:created_at_gteq].present?
      params[:reports][:created_at_gteq] =
        params[:reports][:created_at_gteq].to_date.beginning_of_day
    end
    if params[:reports][:created_at_lteq].present?
      params[:reports][:created_at_lteq] =
        params[:reports][:created_at_lteq].to_date.end_of_day
    end
    search = LogTransaction.ransack(params[:reports])
    transactions_by_user = search.result.select(:user_id, 'sum(log_transactions.amount) as total_amount')
                                 .where(type: %w[net_income sold_channel_subscription sold_channel_gift_subscription])
                                 .group(:user_id).reorder(:user_id)
    csv = CSV.generate(headers: true) do |csv|
      csv << [
        'User',
        # 'Type',
        'Item ID',
        'Item Type',
        'Item Name',
        'Created At',
        'Customer ID',
        'Customer Name',
        'Customer Email',
        'Payment ID',
        'Revenue',
        'Owner Revenue',
        'Platform Revenue',
        'Tax'
      ]
      transactions_by_user.each do |ltu|
        immerss_total = 0
        revenue_total = 0
        tax_total = 0
        search.result.where(type: %w[net_income sold_channel_subscription sold_channel_gift_subscription],
                            user_id: ltu.user_id).each do |lt|
          immerss_profit_margin_percent = 100 - lt.user.revenue_percent.to_i
          immerss_revenue = (lt.amount * immerss_profit_margin_percent / lt.user.revenue_percent.to_i).round(2)
          immerss_total += immerss_revenue
          revenue = if lt.payment_transaction
                      begin
                        lt.payment_transaction.amount / 100.0
                      rescue StandardError
                        (immerss_revenue + lt.amount)
                      end
                    else
                      immerss_revenue + lt.amount
                    end.round(2)
          # negative revenue if refund
          revenue *= -1 if lt.amount.negative?
          revenue_total += revenue
          customer = lt.payment_transaction.try(:user)
          item_type = if lt.abstract_session_type == 'StripeDb::Plan'
                        if lt.type == 'sold_channel_gift_subscription'
                          'Channel Gift Subscription'
                        else
                          'Channel Subscription'
                        end
                      else
                        lt.abstract_session_type
                      end
          tax_amount = lt.payment_transaction.try(:tax_amount) || 0.0
          # negative tax if refund
          tax_amount *= -1 if lt.amount.negative?
          tax_total += tax_amount
          csv << [
            lt.user.public_display_name,
            # lt.type,
            lt.abstract_session_id,
            item_type,
            lt.abstract_session.try(:title),
            lt.created_at,
            customer.try(:id),
            ([customer.try(:first_name), customer.try(:last_name)].compact.join(' ') || customer.try(:display_name)),
            customer.try(:email),
            lt.payment_transaction.try(:pid) || lt.data[:charge_id],
            revenue,
            lt.amount,
            immerss_revenue,
            tax_amount
          ]
        end
        csv << ['', '', '', '', '', '', '', '', 'Totals:', revenue_total, ltu.total_amount, immerss_total, tax_total]
        csv << ['', '', '', '', '', '', '', '', '', '', '', '']
      end
    end
    filename = 'Report'
    if params[:reports]
      if params[:reports][:created_at_gteq] && params[:reports][:created_at_lteq]
        filename += "(#{params[:reports][:created_at_gteq]} - #{params[:reports][:created_at_lteq]})"
      elsif params[:reports][:created_at_gteq]
        filename += "(From:#{params[:reports][:created_at_gteq]})"
      elsif params[:reports][:created_at_lteq]
        filename += "(To:#{params[:reports][:created_at_lteq]})"
      end
      if params[:reports][:user_id_eq]
        filename += "(User##{params[:reports][:user_id_eq]})"
      end
    end
    filename += '.csv'
    respond_to do |format|
      format.html { redirect_to collection_path }
      format.csv { send_data csv, filename: filename }
    end
  end

  index do
    selectable_column
    column :id
    column :user
    column :amount
    column :created_at
    column :payment_transaction
    column :type
    column :data
    column 'Item', &:abstract_session

    actions
  end
  form do |f|
    f.inputs do
      f.input :user, as: :select, collection: User.all.order(display_name: :asc).pluck(:display_name, :id)
      f.input :amount
      f.input :type, as: :select, collection: LogTransaction::Types::ALL
      f.input :data, as: :string
      f.input :abstract_session_id
      f.input :abstract_session_type
      f.input :created_at, as: :datepicker
      f.input :payment_transaction_id
      f.input :payment_transaction_type
    end
    f.actions
  end
  sidebar 'Reports', only: :index do
    users = User.joins(:log_transactions).order('users.display_name ASC').distinct
    render partial: 'report_form', locals: { users: users }
  end
  csv do
    column(:id)
    column(:user_id)
    column(:email) do |obj|
      obj.user.email
    end
    column(:amount)
    column(:type)
    column(:data)
    column(:item_id, &:abstract_session_id)
    column(:item_type, &:abstract_session_type)
    column(:created_at)
  end

  controller do
    def permitted_params
      params.permit!
      if params[:action] == 'create' || params[:action] == 'update'
        params.tap do |attrs|
          json = attrs[:log_transaction][:data].gsub(/:([a-z_0-9]{1,})\s*=>/, '"\1":').gsub(/"([a-z_0-9]{1,})"\s*=>/,
                                                                                            '"\1":')
          attrs[:log_transaction][:data] = JSON.parse(json)
        end
      end
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
