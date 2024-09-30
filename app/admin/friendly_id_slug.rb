# frozen_string_literal: true

ActiveAdmin.register FriendlyId::Slug do
  menu parent: 'System'

  actions :all
  filter :id
  filter :slug
  filter :sluggable_id, label: 'Sluggable ID'
  filter :sluggable_type
  filter :scope
  filter :created_at

  index do
    selectable_column
    column :id
    column :slug
    column 'Sluggable ID', sortable: 'friendly_id_slugs.sluggable_id', &:sluggable_id
    column :sluggable_type
    column :scope
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
