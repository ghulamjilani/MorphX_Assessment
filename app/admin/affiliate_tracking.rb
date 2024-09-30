# frozen_string_literal: true

ActiveAdmin.register_page 'Affiliate Tracking' do
  content title: 'Tracking Info' do
    panel 'Visits' do
      render partial: 'index'
    end
  end
  sidebar :filters, partial: 'filters', only: :index
  sidebar 'Reports', only: :index do
    render partial: 'report_form', locals: { refc_users: @refc_users }
  end
  page_action :generate_report do
    where_attrs = {}
    if params[:refc_user]
      where_attrs[:refc] = params[:refc_user]
    elsif params[:refc]
      where_attrs[:refc] = params[:refc]
    end
    where_attrs[:created_at] = { '$gte': params[:created_at_start] } if params[:created_at_start]
    where_attrs[:created_at] = { '$lte': params[:created_at_end] } if params[:created_at_end]
    where_attrs[:user_id] = { '$ne': nil } if params[:registered]
    where_attrs[:user_id] = nil if params[:not_registered]
    where_attrs[:first] = /cmp=#{params[:campaign]}/i if params[:campaign]

    @items = VisitorSource.where(where_attrs).order(created_at: -1)
    csv = CSV.generate(headers: true) do |csv|
      csv << [
        'Campaign',
        'Ref Code',
        'Ref User ID',
        'Ref User Name',
        'Registered User ID',
        'Registered User Name',
        'Created At',
        'Enter Point',
        'Referer',
        'Browser'
      ]
      @items.each do |item|
        refc_user = item.refc ? ReferralCode.find_by(code: item.refc)&.user : nil
        reg_user = item.user_id ? User.find_by(id: item.user_id) : nil
        csv << [
          item.campaign,
          item.refc,
          refc_user&.id,
          refc_user&.public_display_name,
          reg_user&.id,
          reg_user&.public_display_name,
          item.created_at,
          item.enter_point,
          item.referer,
          item.browser
        ]
      end
    end

    filename = 'affiliate_tracking_report.csv'
    respond_to do |format|
      format.csv { send_data csv, filename: filename }
    end
  end

  controller do
    def permitted_params
      params.permit!
    end

    def index
      where_attrs = {}
      if params[:q]
        if params[:q][:refc_user]
          where_attrs[:refc] = params[:q][:refc_user]
        elsif params[:q][:refc]
          where_attrs[:refc] = params[:q][:refc]
        end
        where_attrs[:created_at] = { '$gte': params[:q][:created_at_start] } if params[:q][:created_at_start]
        where_attrs[:created_at] = { '$lte': params[:q][:created_at_end] } if params[:q][:created_at_end]
        where_attrs[:user_id] = { '$ne': nil } if params[:q][:registered]
        where_attrs[:user_id] = nil if params[:q][:not_registered]
        where_attrs[:first] = /cmp=#{params[:q][:campaign]}/i if params[:q][:campaign]
      end
      @items = VisitorSource
               .where(where_attrs)
               .page(params[:page] || 1).per(30).order(created_at: -1)
      # @refc_users = User.joins(:referral_codes).order(display_name: :asc).select(:id, :display_name).uniq
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end

# table_for items do
#   column('visitor_id') {|item| item.visitor_id}
#   column('refc') {|item| item.refc}
#   column('user_id') {|item| item.user_id}
#   column('current') {|item| item.current}
#   column('current_add') {|item| item.current_add}
#   column('first') {|item| item.first}
#   column('first_add') {|item| item.first_add}
#   column('session') {|item| item.session}
#   column('udata') {|item| item.udata}
#   column('created_at') {|item| item.created_at}
#   column('updated_at') {|item| item.updated_at}
# end
