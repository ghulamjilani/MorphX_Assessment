# frozen_string_literal: true

class RequestSession
  include ActiveModel::Model

  module DeliveryMethods
    IMMERSIVE  = 'Interactive'
    LIVESTREAM = 'Livestream'
  end

  module ImmerssiveTypes
    GROUP      = 'Group Type'
    ONE_ON_ONE = 'One-on-One Type'
  end

  attr_accessor :current_user, :channel, :requested_at, :comment, :delivery_method

  validates :comment, presence: true
  validates :requested_at, presence: true

  # @return[Mailboxer::Message]
  def mailboxer_message
    @mailboxer_message ||= begin
      message_timestamp = Time.now

      convo = Mailboxer::ConversationBuilder.new({
                                                   subject: subject,
                                                   created_at: message_timestamp,
                                                   updated_at: message_timestamp
                                                 }).build

      attachment = nil
      obj = Mailboxer::Message.new
      obj.sender       = current_user
      obj.conversation = convo
      obj.recipients   = [recipient]
      obj.body         = body
      obj.subject      = subject
      obj.attachment   = attachment
      obj.created_at   = message_timestamp
      obj.updated_at   = message_timestamp

      is_read = false
      mailbox_type = 'inbox'
      receipt = Mailboxer::ReceiptBuilder.new({
                                                notification: obj,
                                                mailbox_type: mailbox_type,
                                                receiver: recipient,
                                                is_read: is_read
                                              }).build
      receipt.save

      is_read = true
      mailbox_type = 'sentbox'
      receipt = Mailboxer::ReceiptBuilder.new({
                                                notification: obj,
                                                mailbox_type: mailbox_type,
                                                receiver: current_user,
                                                is_read: is_read
                                              }).build
      receipt.save

      obj
    end
  end

  private

  def recipient
    channel.organizer
  end

  def subject
    "Another session of #{channel.always_present_title} was requested"
  end

  def body
    user_link = if current_user.has_owned_channels?
                  %(<a target="_blank" href="#{current_user.absolute_path}">#{current_user.public_display_name}</a>)
                else
                  %(<a>#{current_user.public_display_name}</a>)
                end

    channel_link = %(<a target="_blank" href="#{channel.absolute_path}">#{channel.always_present_title}</a>)

    result = I18n.t('sessions.another_one_requested',
                    user_link: user_link,
                    channel_link: channel_link,
                    time: requested_at.in_time_zone(recipient.timezone).strftime('%d %b %I:%M %p %Z'))

    if delivery_method.to_s.strip.present?
      suffix = delivery_method.to_s.strip

      result += "\n\nDelivery Method: \n<strong>#{suffix}</strong>"
    end

    if comment.to_s.strip.present?
      result += "\n\nComment:\n<blockquote><strong>#{comment.to_s.strip}</strong></blockquote>"
    end

    result
  end
end
