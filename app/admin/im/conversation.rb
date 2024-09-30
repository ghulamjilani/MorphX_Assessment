# frozen_string_literal: true

ActiveAdmin.register ::Im::Conversation do
  menu parent: 'IM'

  actions :all, except: %i[destroy]

  filter :id
  filter :conversationable_id
  filter :conversationable_type
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    column 'id' do |conversation|
      link_to conversation.id, service_admin_panel_im_conversation_path(conversation)
    end
    column :conversationable
    column :conversationable_id
    column :conversationable_type
    column :created_at
    column :last_message do |conversation|
      link_to(conversation.last_message.body.to_s.first(64), service_admin_panel_im_message_path(conversation.last_message)) if conversation.last_message
    end
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
