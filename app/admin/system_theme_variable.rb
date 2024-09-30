# frozen_string_literal: true

ActiveAdmin.register SystemThemeVariable do
  menu parent: 'Customization'
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs do
      f.input :system_theme, required: true
      f.input :name, required: true
      f.input :group_name, as: :select, collection: %w[background buttons toggless typographics shadows borders],
                           required: true
      f.input :property, required: true
      f.input :state, as: :select, collection: %w[main hover focus disabled active], required: true
      f.input :value, required: true # , as: :color
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
