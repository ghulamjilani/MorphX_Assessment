# frozen_string_literal: true

ActiveAdmin.register SystemTheme do
  menu parent: 'Customization'
  action_item :seed_themes, only: :index do
    link_to('Seed themes', seed_themes_service_admin_panel_system_themes_path, method: :post)
  end

  collection_action :seed_themes, method: :post do
    load File.join(Rails.root, 'db', 'seeds', 'system_themes.rb')

    redirect_to collection_path, alert: 'Themes updated'
  end

  show do
    attributes_table do
      row :name
      row :is_default
      row :custom_css
      table_for system_theme.system_theme_variables.order(created_at: :asc) do
        column 'Variables' do |variable|
          link_to variable.name, [:service_admin_panel, variable]
        end
        column :group_name
        column :property
        column :value
        column :state
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :name, required: true
      f.input :is_default, required: true
      f.input :custom_css, required: true
    end
    f.has_many :system_theme_variables,
               for: [:system_theme_variables, f.object.system_theme_variables.order(created_at: :asc)], heading: false do |p|
      p.inputs class: 'theme-variable', 'data-group': p.object.group_name do
        p.input :name, required: true, label: false
        p.input :value, required: true, label: false
        # p.input :value, required: true, label: false, as: :color
        p.input :group_name, as: :select, label: false,
                             collection: %w[background buttons toggless typographics shadows borders], required: true
        p.input :property, required: true, label: false
        p.input :state, as: :select, label: false, collection: %w[main hover focus disabled active], required: true
      end
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
