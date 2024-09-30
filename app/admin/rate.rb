# frozen_string_literal: true

ActiveAdmin.register Rate do
  menu parent: 'System'
  filter :id
  filter :rater_id, as: :select, collection: proc { User.all.order(display_name: :asc).pluck(:display_name, :id) }
  filter :rateable_id, label: 'Rateable ID'
  filter :rateable_type
  filter :stars
  filter :dimension
  filter :created_at

  index do
    selectable_column
    column :id
    column :rater
    column :rateable
    column :rateable_id
    column :rateable_type
    column :stars
    column :dimension
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
