# frozen_string_literal: true

ActiveAdmin.register UserImage do
  menu parent: 'Images'
  actions :all, except: %i[new create edit update]

  filter :user_id, as: :select, collection: proc { User.all.order(display_name: :asc).pluck(:display_name, :id) }
  filter :created_at
  filter :updated_at

  member_action :recreate_versions, method: :put do
    resource.original_image.recreate_versions!
    redirect_to resource_path, notice: 'Tadaaaaam!'
  rescue StandardError => e
    redirect_to resource_path, notice: e.message
  end

  action_item :recreate_versions, only: :show do
    link_to 'Recreate versions', recreate_versions_service_admin_panel_user_image_path(resource), method: :put
  end

  index do
    selectable_column
    column :id
    column :user
    column :image do |obj|
      img(src: obj.original_image.medium.url, width: 200)
    end
    column :created_at

    actions
  end

  show do
    attributes_table do
      row :id
      row :small do |ci|
        image_tag ci.original_image.small.url
      end
      row :medium do |ci|
        image_tag ci.original_image.medium.url
      end
      row :large do |ci|
        image_tag ci.original_image.large.url
      end
      row :original do |ci|
        image_tag ci.original_image.url
      end
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
