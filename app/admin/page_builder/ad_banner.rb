# frozen_string_literal: true

ActiveAdmin.register ::PageBuilder::AdBanner do
  menu parent: 'Advertisement'

  actions :all

  filter :id
  filter :name
  filter :key
  filter :url
  filter :archived
  filter :created_at

  index do
    selectable_column
    column :id
    column :file do |obj|
      image_tag obj.file.small.url, style: 'height:100px;width:auto;'
    end
    column :name
    column :key
    column :url
    column :total_clicks do |obj|
      obj.ad_clicks.count
    end
    column :guest_clicks do |obj|
      obj.ad_clicks.where(user_id: nil).count
    end
    column :user_clicks do |obj|
      obj.ad_clicks.where.not(user_id: nil).count
    end
    column :archived
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :key
      row :file do |obj|
        image_tag obj.file.small.url, style: 'height:100px;width:auto;'
      end
      row :url
      row :archived
      row :created_at
    end
  end

  form do |f|
    f.inputs do
      f.input :name, required: true
      f.input :key, required: true
      f.input :url, as: :string, required: true
      f.input :file, as: :file, required: true, input_html: { accept: '.jpg, .jpeg, .png' }
      f.input :archived
    end
    f.actions
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
