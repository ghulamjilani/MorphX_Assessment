# frozen_string_literal: true

ActiveAdmin.register MarketingTools::OptInModal, as: 'Opt-in Modals' do
  menu parent: 'Marketing Tools'

  actions :all

  index do
    selectable_column
    id_column
    column :title
    column :channel
    column :views_count
    column :submits_count
    column :active
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :title
      row :description
      row :trigger_time
      row :channel
      row :system_template
      row :views_count
      row :submits_count
      row :active
      row :updated_at
      row :created_at
    end
  end

  form do |f|
    f.inputs 'Modal Details' do
      f.input :channel_uuid, as: :string
      f.input :title
      f.input :description
      f.input :trigger_time
      f.input :active
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
