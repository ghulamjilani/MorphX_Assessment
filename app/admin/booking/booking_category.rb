# frozen_string_literal: true

ActiveAdmin.register Booking::BookingCategory do
  menu parent: 'Booking'

  actions :all, except: :destroy

  action_item :seed, only: :index do
    link_to('Seed categories', seed_service_admin_panel_booking_booking_categories_path, method: :post)
  end

  collection_action :seed, method: :post do
    load File.join(Rails.root, 'db', 'seeds', 'booking_categories.rb')

    redirect_to collection_path, alert: 'Categories updated'
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
