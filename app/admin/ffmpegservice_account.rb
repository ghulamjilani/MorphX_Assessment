# frozen_string_literal: true

ActiveAdmin.register FfmpegserviceAccount do
  menu parent: 'Ffmpegservice'

  filter :id
  filter :stream_id
  filter :protocol
  filter :organization_id
  filter :user_id
  filter :sandbox
  filter :current_service
  filter :custom_name
  filter :delivery_method
  filter :authentication
  filter :transcoder_type
  filter :stream_name

  scope(:all)
  scope(:assigned, &:assigned)
  scope(:not_assigned, &:not_assigned)
  scope(:reserved, &:reserved)
  scope(:not_reserved, &:not_reserved)

  index do
    selectable_column
    column :id
    column :sandbox
    column :user
    column :organization
    column :stream_id
    column :protocol
    column :current_service
    column :reserved_by
    column :reserved_by_type
    column :custom_name
    column :delivery_method
    column :authentication
    column :transcoder_type
    column :stream_name
    actions defaults: true, confirm: 'Are you sure?' do |wa|
      "<br>#{link_to 'Nullify', nullify_service_admin_panel_ffmpegservice_account_path(wa),
                     data: { confirm: 'Are you sure?' }, class: 'member_link'}".html_safe
    end
  end

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end

  member_action :toggle_authentication, method: :get do
    resource.update_columns(authentication: !resource.authentication)
    FfmpegserviceAccountJobs::SyncTranscoderAuthentication.new.perform(resource.id)
    flash[:success] = (resource.authentication ? 'Authentication enabled' : 'Authentication disabled')
    redirect_back fallback_location: service_admin_panel_ffmpegservice_account_path(resource)
  end

  action_item :toggle_authentication, only: :show do
    link_to "#{resource.authentication ? 'Disable' : 'Enable'} authentication",
            toggle_authentication_service_admin_panel_ffmpegservice_account_path(resource)
  end

  member_action :nullify, method: :get do
    resource.nullify!
    flash[:success] = 'Account nullified'
    redirect_back fallback_location: service_admin_panel_ffmpegservice_account_path(resource)
  end

  action_item :nullify, only: :show do
    link_to 'Nullify', nullify_service_admin_panel_ffmpegservice_account_path(resource)
  end

  action_item :create_webrtc, only: [:index] do
    unless Rails.env.production?
      link_to('Create Live WebRTC', create_webrtc_service_admin_panel_ffmpegservice_accounts_path,
              data: { confirm: 'Are you sure? Be careful: you can create up to 10 ffmpegservice accounts within 3 hours' }, target: '_blank', class: 'member_link')
    end
  end

  collection_action :create_webrtc, method: [:get] do
    wa = FfmpegserviceAccountJobs::Generate.create_webrtc_livestream(false)
    redirect_to service_admin_panel_ffmpegservice_account_path(wa), notice: 'New WebRTC ffmpegservice account has been created.'
  end

  action_item :create_rtmp, only: [:index] do
    unless Rails.env.production?
      link_to('Create Live RTMP', create_rtmp_service_admin_panel_ffmpegservice_accounts_path,
              data: { confirm: 'Are you sure? Be careful: you can create up to 10 ffmpegservice accounts within 3 hours' }, target: '_blank', class: 'member_link')
    end
  end

  collection_action :create_rtmp, method: [:get] do
    wa = FfmpegserviceAccountJobs::Generate.create_livestream(transcoder_type: :passthrough, protocol: :rtmp, sandbox: false)
    redirect_to service_admin_panel_ffmpegservice_account_path(wa), notice: 'New RTMP ffmpegservice account has been created.'
  end

  action_item :create_ipcam, only: [:index] do
    unless Rails.env.production?
      link_to('Create Live Ipcam', create_ipcam_service_admin_panel_ffmpegservice_accounts_path,
              data: { confirm: 'Are you sure? Be careful: you can create up to 10 ffmpegservice accounts within 3 hours' }, target: '_blank', class: 'member_link')
    end
  end

  collection_action :create_ipcam, method: [:get] do
    wa = FfmpegserviceAccountJobs::Generate.create_livestream(transcoder_type: :passthrough, protocol: :rtsp, sandbox: false)
    redirect_to service_admin_panel_ffmpegservice_account_path(wa), notice: 'New Ipcam ffmpegservice account has been created.'
  end

  batch_action :nullify do |ids|
    collection.where(id: ids).find_each(&:nullify!)
    redirect_to collection_path, notice: 'Ffmpegservice Accounts nullified'
  end
end
