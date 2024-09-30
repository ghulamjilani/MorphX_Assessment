# frozen_string_literal: true

ActiveAdmin.register UserAccount do
  menu parent: 'User'

  actions :all, except: %i[new create edit update destroy]
  filter :user_id

  form do |f|
    f.inputs do
      f.input :user
      f.input :city
      f.input :phone
      f.input :found_us_method
      f.input :country_state
      f.input :video_id
      f.input :pin
      f.input :room_id
      f.input :available_by_request_for_live_vod, as: :boolean
      f.input :tagline
      f.input :bio
      f.input :image
      f.input :contact_email
      f.input :original_bg_image
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
