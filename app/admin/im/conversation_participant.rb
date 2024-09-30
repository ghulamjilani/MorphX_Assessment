# frozen_string_literal: true

ActiveAdmin.register ::Im::ConversationParticipant do
  menu parent: 'IM'

  actions :all

  filter :id
  filter :conversation_id, as: :string, label: 'Conversation ID'
  filter :abstract_user_id, as: :string, label: 'Abstract User ID'
  filter :abstract_user_type, as: :select, collection: %w[User Guest]
  filter :banned
  filter :created_at

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
