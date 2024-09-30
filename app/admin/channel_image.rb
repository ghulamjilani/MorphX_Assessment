# frozen_string_literal: true

ActiveAdmin.register ChannelImage do
  menu parent: 'Images'

  actions :all, except: %i[new create edit update]

  filter :channel, as: :select, collection: proc { Channel.all.order(title: :asc).pluck(:title, :id) }
  filter :is_main, as: :check_boxes, collection: [['Yes', true], ['No', false]]
  filter :image_processing, as: :check_boxes, collection: [['Yes', true], ['No', false]]
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
    link_to 'Recreate versions', recreate_versions_service_admin_panel_channel_image_path(resource), method: :put
  end

  index do
    selectable_column
    column :id
    column :channel
    column :is_main
    column :image_processing
    column :image do |obj|
      img(src: obj.image_tile_url, width: 485)
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
      row :preview do |ci|
        image_tag ci.image_preview_url
      end
      row :mobile_preview do |ci|
        image_tag ci.image_mobile_preview_url
      end
      row :slider do |ci|
        image_tag ci.image_slider_url
      end
      row :tile do |ci|
        image_tag ci.image_tile_url
      end
      row :gallery do |ci|
        image_tag ci.image_gallery_url
      end
      row :image do |ci|
        image_tag ci.image_url
      end
      row :original do |ci|
        image_tag ci.original_image_url
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :channel
      f.input :image
      f.input :place_number
      f.input :description
      f.input :is_main
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
