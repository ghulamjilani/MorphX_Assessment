# frozen_string_literal: true

ActiveAdmin.register Booking::BookingSlot do
  menu parent: 'Booking'

  actions :all, except: :destroy

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
