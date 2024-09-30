# frozen_string_literal: true

ActiveAdmin.register RecordedMember do
  menu parent: 'Sessions'
  actions :all, except: %i[edit destroy]

  filter :id
  filter :abstract_session_id
  filter :abstract_session_type, as: :select, collection: proc { %w[Recording Session] }
  filter :participant, as: :select, collection: proc {
                                                  Participant.joins(:user).order(Arel.sql('LOWER(users.display_name) ASC')).map do |p|
                                                    [p&.user&.display_name, p.id]
                                                  end
                                                }
  filter :status
  filter :created_at

  index do
    selectable_column
    column :id
    column :abstract_session
    column :participant
    column :status
    column :created_at
    actions
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :abstract_session_id
      f.input :abstract_session_type, as: :select, collection: %w[Recording Session], selected: 'Session'
      f.input :participant_id, as: :select, collection: Participant.joins(:user).order(Arel.sql('LOWER(users.display_name) ASC')).map { |p|
                                                          [p&.user&.display_name, p.id]
                                                        }
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
