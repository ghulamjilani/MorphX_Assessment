# frozen_string_literal: true

class ConversationsController < ApplicationController
  before_action :authenticate_user!
  protect_from_forgery except: [:preview_modal]
  def preview_modal
    @conversation = Mailboxer::Conversation.find_by(id: params[:id])

    if @conversation.nil? || !@conversation.is_participant?(current_user)
      raise 'not permitted'
    end

    mailbox = current_user.mailbox
    @receipts = mailbox.receipts_for(@conversation).not_trash

    respond_to do |format|
      format.js do
        render "conversations/#{__method__}"
        @receipts.mark_as_read
        Rails.cache.delete(current_user.unread_messages_count_cache)
      end
    end
  end
end
