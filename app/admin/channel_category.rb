# frozen_string_literal: true

ActiveAdmin.register ChannelCategory do
  menu parent: 'Admin settings'

  form do |f|
    f.inputs do
      f.input :name
      f.input :featured, as: :boolean
      f.input :description_in_markdown_format
    end
    f.actions
  end

  index do
    selectable_column
    column :id
    column :name
    column :description_in_markdown_format
    column :featured
    column :channels_count do |resource|
      link_to resource.channels.count,
              service_admin_panel_channels_path(q: { category_id_equals: resource.id }, commit: 'Filter')
    end
    column :created_at
    column :updated_at

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
