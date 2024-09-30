# frozen_string_literal: true

ActiveAdmin.register PgSearchDocument do
  menu parent: 'System'

  filter :id
  filter :user_id
  filter :channel_id
  filter :searchable_type
  filter :searchable_id
  filter :title
  filter :status
  filter :duration
  filter :updated_at

  index do
    selectable_column
    column :id
    column :searchable
    column :searchable_type
    column :user, sortable: :user_id
    column :user_id
    column :channel, sortable: :channel_id
    column :channel_id
    column :duration
    column :status
    column :views_count
    column :promo_weight
    column :updated_at

    actions
  end

  actions :all, except: %i[new create edit destroy]

  show do
    attributes_table do
      row :id
      row :searchable
      row :content
      row :tsv
      row :title
      row :tsv_title
      (resource.attributes.keys - %w[id content tsv title tsv_title created_at updated_at]).each do |attr|
        row attr
      end
      row :created_at
      row :updated_at
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
end
