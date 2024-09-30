# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :authenticate_user!

  before_action :set_current_organization
  before_action :get_mailbox, :get_box
  before_action :check_current_subject_in_conversation, only: %i[show update destroy]

  protect_from_forgery except: :new


  def index
    conversations = case @box
                    when 'inbox'
                      @mailbox.inbox
                    when 'sentbox'
                      @mailbox.sentbox
                    else
                      @mailbox.trash
                    end
    @conversations = conversations.page(params[:page]).per(4)
    respond_to do |format|
      format.html
      format.json
    end
  end

  def new
    @recipient = begin
      User.friendly.find(params[:receiver])
    rescue StandardError
      nil
    end
    # TODO: Add support for messages to organization
    # || Organization.where('organizations.slug = :slug OR organizations.id = :id', slug: params[:receiver], id: params[:receiver].to_i).last

    respond_to do |format|
      format.html { redirect_back fallback_location: root_path }
      # format.html { redirect_to root_path(autodisplay_remote_ujs_path: request.original_fullpath) }
      format.js { render "messages/#{__method__}" }
    end
  end

  def create
    @recipient = begin
      User.friendly.find(params[:message][:recipient])
    rescue StandardError
      nil
    end
    # TODO: Add support for messages to organization
    # || Organization.where('organizations.slug = :slug OR organizations.id = :id', slug: params[:message][:recipient], id: params[:message][:recipient].to_i).last
    @receipt = current_user.send_message(@recipient, params[:message][:body], params[:message][:subject])
    @receipt.valid?
    if @receipt.errors.blank?
      Rails.cache.delete(@recipient.unread_messages_count_cache) if @recipient.respond_to?(:unread_messages_count_cache)

      if @recipient.present? && @recipient.is_a?(User)
        UsersChannel.broadcast_to(@recipient, event: 'unread-messages-count',
                                              data: @recipient.unread_messages_count)
      end
    else
      Rails.logger.info @receipt.errors.full_messages
    end

    respond_to do |format|
      format.json
      format.js
    end
  end

  def show
    @receipts = if @box.eql? 'trash'
                  @mailbox.receipts_for(@conversation).trash
                else
                  @mailbox.receipts_for(@conversation).not_trash
                end
    render action: :show
    @receipts.mark_as_read
    Rails.cache.delete(current_user.unread_messages_count_cache)
  end

  def update
    if params[:untrash].present?
      @conversation.untrash(current_user)
    end

    if params[:reply_all].present?
      last_receipt = @mailbox.receipts_for(@conversation).last
      @receipt = current_user.reply_to_all(last_receipt, params[:body])
    end

    @receipts = if @box.eql? 'trash'
                  @mailbox.receipts_for(@conversation).trash
                else
                  @mailbox.receipts_for(@conversation).not_trash
                end
    redirect_to action: :show
    @receipts.mark_as_read
    Rails.cache.delete(current_user.unread_messages_count_cache)
  end

  def destroy
    @conversation.move_to_trash(current_user)
    if params[:location].present? and params[:location] == 'conversation'
      redirect_to messages_path(box: :trash)
    else
      redirect_to messages_path(box: @box, page: params[:page])
    end
  end

  private

  def get_mailbox
    @mailbox = current_user.mailbox
  end

  def get_box
    params[:box] = 'inbox' if params[:box].blank? or %w[inbox sentbox trash].exclude?(params[:box])

    @box = params[:box]
  end

  def check_current_subject_in_conversation
    @conversation = Mailboxer::Conversation.find_by(id: params[:id])

    if @conversation.nil? or !@conversation.is_participant?(current_user)
      redirect_to messages_path(box: @box)
      return
    end
  end

  def set_current_organization
    @current_organization = @organization = current_user&.current_organization
  end
end
