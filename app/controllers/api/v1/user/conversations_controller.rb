# frozen_string_literal: true

class Api::V1::User::ConversationsController < Api::V1::User::ApplicationController
  before_action :set_mailbox
  before_action :set_conversation, only: %i[show mark_as_read mark_as_unread]
  before_action :offset_limit

  def index
    query = @mailbox
    query = case params[:box]
            when 'inbox'
              query.inbox
            when 'sentbox'
              query.sentbox
            when 'trash'
              query.trash
            else
              query.conversations
            end

    @count = query.count
    order_by = %w[created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
    @conversations = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
  end

  def show
    @receipts = @receipts.limit(@limit).offset(@offset)
  end

  def destroy
    conversations = @mailbox.conversations
    if params[:id].eql? 'all'
      conversations.find_each { |conversation| conversation.mark_as_deleted(current_user) }
    else
      conversations.where(id: params[:id]).find_each { |conversation| conversation.mark_as_deleted(current_user) }
    end
    @conversations = @mailbox.conversations
    @count = @conversations.count
    @conversations = @conversations.limit(@limit).offset(@offset)
    render :index
  end

  def mark_as_read
    @conversation.mark_as_read(current_user)
    render :show
  end

  def mark_as_unread
    @conversation.mark_as_unread(current_user)
    render :show
  end

  private

  def set_mailbox
    @mailbox = current_user.mailbox
  end

  def set_conversation
    @conversation = @mailbox.conversations.find(params[:id])
    @receipts = @conversation.receipts_for(current_user).not_deleted
    @receipts_count = @receipts.count
  end

  def offset_limit
    @offset = (params[:offset].to_i >= 0) ? params[:offset].to_i : 0
    @limit = (1..300).cover?(params[:limit].to_i) ? params[:limit].to_i : 20
  end
end
