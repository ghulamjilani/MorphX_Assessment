# frozen_string_literal: true

ActiveAdmin.register ::Im::Message do
  menu parent: 'IM'

  before_action only: :index do
    @per_page = 100 unless params[:per_page]
  end

  config.sort_order = 'created_at_desc'

  scope(:all)
  scope(:deleted, &:deleted)
  scope(:not_deleted, &:not_deleted)

  actions :all, except: %i[edit]

  filter :id
  filter :conversation_id, as: :string, label: 'Conversation ID'
  filter :conversation_participant_id, as: :string, label: 'Conversation Participant ID'
  filter :deleted_at
  filter :created_at

  batch_action :destroy do |ids|
    messages = ::Im::Message.where(id: ids)
    messages.each(&:destroy)

    redirect_to collection_path, alert: 'Selected messages destroyed'
  end

  batch_action :mark_as_deleted do |ids|
    messages = ::Im::Message.where(id: ids)
    messages.find_each(&:deleted!)

    redirect_to collection_path, alert: 'Selected messages marked as deleted'
  end

  batch_action :restore do |ids|
    messages = ::Im::Message.where(id: ids)
    messages.find_each(&:restore!)

    redirect_to collection_path, alert: 'Selected messages marked as deleted'
  end

  member_action :mark_as_deleted, method: :put do
    resource.update(deleted_at: Time.now.utc)
    redirect_back fallback_location: collection_path, notice: 'Message marked as deleted'
  end

  member_action :restore, method: :put do
    resource.update(deleted_at: nil)
    redirect_back fallback_location: collection_path, notice: 'Message restored'
  end

  action_item :mark_as_deleted, only: :show do
    link_to('Mark as deleted', mark_as_deleted_service_admin_panel_im_message_path(resource), method: :put) unless resource.deleted?
  end

  action_item :restore, only: :show do
    link_to('Restore', restore_service_admin_panel_im_message_path(resource), method: :put) if resource.deleted?
  end

  index do
    selectable_column
    column :conversation
    column :conversation_participant
    column 'Author', &:abstract_user
    column 'Guest' do |message|
      !message.abstract_user.is_a?(User)
    end
    column(:conversationable, &:conversationable)
    column 'Conversationable Type' do |message|
      message.conversationable.class.name if message.conversationable.present?
    end
    column :body do |message|
      link_to message.body.to_s.first(60), service_admin_panel_im_message_path(message)
    end
    column :deleted do |message|
      status_tag(message.deleted_at.present?, title: message.deleted_at)
    end
    column :created_at
    actions defaults: true, confirm: 'Are you sure?' do |message|
      if message.deleted?
        link_to('Restore', restore_service_admin_panel_im_message_path(message), method: :put) if message.deleted?
      else
        link_to('Mark as deleted', mark_as_deleted_service_admin_panel_im_message_path(message), method: :put)
      end
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
