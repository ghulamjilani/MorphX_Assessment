# frozen_string_literal: true

ActiveAdmin.register CompanySetting do
  menu parent: 'Settings'

  actions :all
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :organization_id, label: 'Organization ID'
      f.input :logo_image
      f.input :logo_channel_link, as: :boolean
      f.input :custom_styles,
              hint: "Copy this into input and change 'red' to custom color number:<br/>.modals_wrapp{<br/>\t--main_color: red;<br/>}".html_safe
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
