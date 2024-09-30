# frozen_string_literal: true

ActiveAdmin.register VideoImage do
  menu parent: 'Images'

  actions :all, except: %i[new create edit update]

  filter :video_id, label: 'Video ID'
  filter :video_title_cont, label: 'Video Title'
  filter :created_at
  filter :updated_at

  member_action :recreate_versions, method: :put do
    # resource.process_image_upload = true
    resource.image.recreate_versions!
    redirect_to resource_path, notice: 'Tadaaaaam!'
  rescue StandardError => e
    redirect_to resource_path, notice: e.message
  end

  action_item :recreate_versions, only: :show do
    link_to 'Recreate versions', recreate_versions_service_admin_panel_video_image_path(resource), method: :put
  end

  index do
    selectable_column
    column :id
    column :video
    column :image do |obj|
      img(src: obj.image.url, width: 485)
    end
    column :created_at

    actions
  end

  show do
    attributes_table do
      row :id
      row :crop_x
      row :crop_y
      row :crop_w
      row :crop_h
      row :rotate
      row :tile do |ci|
        image_tag ci.image.url
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :video
      f.input :image
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
