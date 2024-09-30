# frozen_string_literal: true

ActiveAdmin.register Storage::Record do
  menu parent: 'Usage'
  actions :all, except: %i[new create edit update destroy]

  filter :id
  filter :model_type
  filter :model_id, label: 'Model Id'
  filter :relation_type
  filter :object_type
  filter :object_id, label: 'Object Id'
  filter :s3_bucket_name
  filter :blob_id, label: 'Blob Id'
  filter :byte_size

  index do
    column :id
    column :organization
    column :model
    column :model_id
    column :model_type
    column :relation_type
    column :byte_size
    column :object_type
    column :object_id
    column :s3_bucket_name
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
