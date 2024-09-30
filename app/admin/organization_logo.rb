# frozen_string_literal: true

ActiveAdmin.register OrganizationLogo do
  menu parent: 'Images'
  actions :all, except: :destroy

  member_action :recreate_versions, method: :put do
    resource.image.recreate_versions!
    redirect_to resource_path, notice: 'Tadaaaaam!'
  rescue StandardError => e
    redirect_to resource_path, notice: e.message
  end

  action_item :recreate_versions, only: :show do
    link_to 'Recreate versions', recreate_versions_service_admin_panel_organization_logo_path(resource), method: :put
  end

  filter :organization_id, label: 'Organization ID'
  filter :organization_name_cont, label: 'Organization Name'
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    column :id
    column :organization
    column :image do |obj|
      img(src: obj.medium_url, width: 200)
    end
    column :created_at

    actions
  end

  show do
    attributes_table do
      row :id
      row :small do |ci|
        image_tag ci.small_url
      end
      row :medium do |ci|
        image_tag ci.medium_url
      end
      row :image do |ci|
        image_tag ci.image.url
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :organization
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
