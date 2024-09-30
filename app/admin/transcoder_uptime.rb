# frozen_string_literal: true

ActiveAdmin.register TranscoderUptime do
  menu parent: 'Ffmpegservice'

  filter :id
  filter :streamable_id
  filter :streamable_type
  filter :transcoder_id
  filter :uptime_id
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    column :id
    column :streamable
    column :streamable_id
    column :streamable_type
    column :transcoder_id
    column :uptime_id
    column :ffmpegservice_account do |obj|
      FfmpegserviceAccount.find_by(stream_id: obj.transcoder_id)
    end
    column :created_at

    actions
  end

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
