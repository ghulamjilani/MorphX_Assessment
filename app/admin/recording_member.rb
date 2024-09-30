# frozen_string_literal: true

ActiveAdmin.register RecordingMember do
  menu parent: 'User'
  actions :all, except: %i[edit destroy]

  filter :id
  filter :recording_id
  filter :participant_user_id, label: 'User ID'
  filter :participant_user_email_cont, label: 'User email'
  filter :participant_user_display_name_cont, label: 'User name'
  filter :status
  filter :created_at

  index do
    selectable_column
    column :id
    column :recording
    column 'User' do |obj|
      link_to(obj.participant.user.public_display_name, service_admin_panel_user_path(obj.participant.user.id))
    end
    column :status
    column :created_at
    actions
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :recording_id
      f.input :participant_id, label: 'Participant ID'
      f.input :status, value: 'confirmed', input_html: { value: 'confirmed', readonly: 'readonly' }
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
