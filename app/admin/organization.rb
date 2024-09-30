# frozen_string_literal: true

ActiveAdmin.register Organization do
  menu parent: 'System'

  batch_action :recreate_short_url do |ids|
    models = Organization.where(id: ids)
    models.each(&:recreate_short_urls)

    redirect_to collection_path, alert: 'Short url will be recreated soon'
  end

  batch_action :report_revenue_organization do |ids|
    puts ids
    redirect_to service_admin_panel_revenueorganization_path(oid: ids)
  end

  batch_action :update_short_url do |ids|
    models = Organization.where(id: ids)
    models.each(&:update_short_urls)

    redirect_to collection_path, alert: 'Short url will be updated soon'
  end

  batch_action :show_on_home do |ids|
    collection.where(id: ids).update_all(show_on_home: true, hide_on_home: false)
    redirect_to collection_path, alert: 'Organizations updated'
  end

  batch_action :hide_on_home do |ids|
    collection.where(id: ids).update_all(show_on_home: false, hide_on_home: true)
    redirect_to collection_path, alert: 'Organizations updated'
  end

  member_action :refresh_slug, method: :put do
    resource.update(slug: nil)
    redirect_to resource_path, notice: 'Slug updated!'
  end

  action_item :refresh_slug, only: :show do
    link_to 'Refresh slug', refresh_slug_service_admin_panel_organization_path(resource), method: :put
  end

  action_item :create_ffmpegservice_account, only: [:show] do
    unless Rails.env.production?
      link_to('Create Live WA', create_ffmpegservice_account_service_admin_panel_organization_path(organization),
              data: { confirm: 'Are you sure? Be careful: you can create up to 10 ffmpegservice accounts within 3 hours' }, target: '_blank', class: 'member_link')
    end
  end

  member_action :create_ffmpegservice_account, method: :get do
    return redirect_back fallback_location: service_admin_panel_organizations_path if Rails.env.production?

    errors = []
    messages = []

    [%w[main push], %w[rtmp push], %w[ipcam pull]].each do |service_type, delivery_method|
      # no wa is available, create a new one
      client = Sender::Ffmpegservice.client(sandbox: false)

      stream = client.create_live_stream(params: {
                                           transcoder_type: 'passthrough',
                                           delivery_method: delivery_method,
                                           name: FfmpegserviceAccount.new(organization_id: resource.id).transcoder_name
                                         })

      raise 'Ffmpegservice response is broken' unless stream[:source_connection_information]

      ffmpegservice_account = FfmpegserviceAccount.create! do |wa|
        wa.user_id = resource.user.id
        wa.organization_id = resource.id
        wa.current_service = service_type
        wa.custom_name = wa.default_custom_name
        wa.delivery_method = delivery_method
        wa.stream_id = stream[:id]
        wa.stream_name = stream[:source_connection_information][:stream_name]
        wa.server = stream[:source_connection_information][:primary_server]
        wa.port = stream[:source_connection_information][:host_port]
        wa.authentication = true
        wa.username = stream[:source_connection_information][:username]
        wa.password = stream[:source_connection_information][:password]
        wa.hls_url = stream[:player_hls_playback_url]
        wa.stream_status = 'off'
        wa.transcoder_type = stream[:transcoder_type]
        wa.name = stream[:name]
        wa.idle_timeout = 1200
        wa.sandbox = false
      end

      update_response = client.update_transcoder(transcoder: {
                                                   idle_timeout: 7200,
                                                   disable_authentication: service_type == 'main'
                                                 })

      if update_response
        ffmpegservice_account.update_columns({ custom_name: ffmpegservice_account.default_custom_name, idle_timeout: 7200,
                                       authentication: service_type != 'main' })
      end

      errors += ffmpegservice_account.errors if ffmpegservice_account.errors.present?
    rescue StandardError => e
      case e
      when Excon::Error::Conflict
        errors << "You've reached the maximum number of stream targets that can be added in a three-hour period. You can add more in 3 hours"
        break
      when Excon::Error::Unauthorized
        errors << 'Make sure api_key and access_key are set in your overriden credentials (backend:initialize:ffmpegservice_account:)'
        break
      when Excon::Error
        errors << "Failed to create new #{service_type} account: failed to get proper response from Ffmpegservice"
      else
        errors << "Failed to create new #{service_type} account, got an error: #{e.message.first(50)}"
      end
    end

    if errors.present?
      flash[:error] = errors.join('. ')
    end

    messages << 'New ffmpegservice accounts have been created for organization'
    flash[:success] = messages.join('. ')
    redirect_back fallback_location: service_admin_panel_organizations_path
  end

  action_item :nullify_ffmpegservice_accounts, only: [:show] do
    link_to('Nullify WA', nullify_ffmpegservice_accounts_service_admin_panel_organization_path(organization),
            data: { confirm: 'Are you sure? Make sure there is no scheduled sessions that use ffmpegservice accounts.' }, target: '_blank', class: 'member_link')
  end

  member_action :nullify_ffmpegservice_accounts, method: :get do
    resource.send :nullify_wa
    flash[:success] = 'Ffmpegservice Accounts nullified'
    redirect_back fallback_location: service_admin_panel_organization_path(resource)
  end

  before_action do
    Organization.class_eval do
      def to_param
        id.to_s
      end
    end
  end

  actions :all

  filter :id
  filter :name
  filter :user_id, label: 'User ID'
  filter :user_email_cont, label: 'User email'
  filter :user_display_name_cont, label: 'User name'
  filter :website_url
  filter :show_on_home, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :hide_on_home, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :slug
  # filter :promo_start
  # filter :promo_end
  filter :promo_weight
  filter :short_url
  filter :fake, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :interactive_guests, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :multiroom_status
  filter :split_revenue_plan

  csv do
    column(:id)
    column(:user_id) { |o| o.user.id }
    column(:user_display_name) { |o| o.user.public_display_name }
    column(:owner_email) { |o| o.user.email }
    column(:name)
    column(:description)
    column(:website_url)
    column(:tagline)
    column(:slug)
    column(:accessible_via_subdomain)
    column(:split_revenue_plan)
    column(:industry_id)
    column(:created_at)
    column(:updated_at)
    column(:show_on_home)
    column(:promo_weight)
    # column(:promo_start)
    # column(:promo_end)
    column(:fake)
  end

  index do
    selectable_column
    column :id
    column :name
    column :user
    column :created_at
    column :website_url
    column :show_on_home
    column :hide_on_home
    column :fake
    column :short_url
    column :multiroom_status
    column :interactive_guests
    column :split_revenue_plan
    column :promo_weight
    column :views_count
    column :unique_views_count

    actions defaults: true, confirm: 'Are you sure?' do |organization|
      unless Rails.env.production?

        "<br>#{link_to 'Create Live WA', create_ffmpegservice_account_service_admin_panel_organization_path(organization),
                       data: { confirm: 'Are you sure? Be careful: you can create up to 10 ffmpegservice accounts within 3 hours' }, target: '_blank', class: 'member_link'}"
          .html_safe
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :user_id
      f.input :name
      f.input :slug
      f.input :promo_weight
      f.input :fake unless current_admin.platform_admin?
      # f.input :promo_start, as: :datepicker
      # f.input :promo_end, as: :datepicker
      f.input :show_on_home, as: :radio, hint: 'Use only one of show/hide on home'
      f.input :hide_on_home, as: :radio, hint: 'Use only one of show/hide on home'
      f.input :split_revenue_plan
      f.input :interactive_guests, as: :boolean
      f.input :enable_free_subscriptions, as: :boolean
      f.input :is_sessions_templates_enabled, as: :boolean
      # f.input :secret_key
      # f.input :secret_token
      f.input :multiroom_status
      # f.input :accessible_via_subdomain, as: :boolean
      f.input :embed_domains, as: :text, input_html: { rows: 6 }
      f.input :stop_no_stream_sessions
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :user
      (resource.attributes.keys - %w[id created_at updated_at fake]).each do |attr|
        row attr
      end
      row :fake unless current_admin.platform_admin?
      row :created_at
      row :updated_at
    end
  end

  controller do
    def permitted_params
      params.permit!
    end

    def find_resource
      if /\A\d+\z/.match?(params[:id])
        scoped_collection.where(id: params[:id]).first!
      else
        scoped_collection.where(slug: params[:id]).first!
      end
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end

    def scoped_collection
      if current_admin.platform_admin?
        super.joins(:user).where(fake: false, users: { fake: false })
      else
        super
      end
    end
  end
end
