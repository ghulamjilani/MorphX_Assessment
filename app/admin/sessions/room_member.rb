# frozen_string_literal: true

ActiveAdmin.register RoomMember do
  menu parent: 'Sessions'
  actions :all

  filter :id
  filter :room_id
  filter :abstract_user_id
  filter :abstract_user_type, as: :select, collection: %w[User Guest]
  filter :kind, as: :select, collection: RoomMember::Kinds::ALL
  filter :joined
  filter :mic_disabled
  filter :video_disabled
  filter :pinned
  filter :created_at

  index do
    selectable_column
    column :id
    column :room
    column :abstract_user
    column :abstract_user_id
    column :abstract_user_type
    column :display_name
    column :kind
    column :joined
    column :banned
    actions
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :mic_disabled
      f.input :video_disabled
      f.input :joined
      f.input :pinned
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
