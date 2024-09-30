# frozen_string_literal: true

ActiveAdmin.register Shop::ProductImage, as: 'Product Image' do
  menu parent: 'Shop'
  actions :all

  filter :product_id, label: 'Product ID'
  filter :product_title_cont, label: 'Product Name'

  index do
    selectable_column
    column :id
    column :product
    column :image do |obj|
      img(src: obj.original_url, width: 100)
    end

    actions
  end
  show do
    attributes_table do
      row :id
      row :product
      row :original_url
      row :image do |pi|
        image_tag pi.original_url
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
