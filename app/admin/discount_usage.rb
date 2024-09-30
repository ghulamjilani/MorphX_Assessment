# frozen_string_literal: true

ActiveAdmin.register DiscountUsage do
  menu parent: 'Ledger'

  actions :all, only: [:index]
  index do
    selectable_column
    column :id
    column :user
    column :discount
    column :created_at
  end

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
