# frozen_string_literal: true

ActiveAdmin.register Shop::Product, as: 'Product' do
  menu parent: 'Shop'
  actions :all
  scope(:all, default: true)
  # scope(:affiliate) { |scope| scope.where.not(affiliate_url: [nil, '']) }

  filter :title
  filter :organization_id_eq, label: 'Organization ID'
  filter :organization_name_cont, label: 'Organization Name'
  filter :price
  filter :url

  index do
    selectable_column
    column :id
    column :image do |obj|
      img(src: obj.image_url, width: 100)
    end
    column :organization
    column :title
    column(:price) { |p| p.price.format }
    column :url
    actions
  end

  form do |f|
    f.inputs do
      f.input :organization_id
      f.input :title
      f.input :url
      f.input :base_url
      f.input :affiliate_url
      f.input :description
      f.input :short_description
      f.input :specifications
      f.input :price_cents
      f.input :price_currency, as: :select, collection: Money::Currency.all.map(&:iso_code)
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
