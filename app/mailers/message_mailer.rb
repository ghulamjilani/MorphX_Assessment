# frozen_string_literal: true

# NOTE: overriding Mailboxer::MessageMailer for UI customization
# to keep it consistent with other mailer actions
class MessageMailer < Mailboxer::BaseMailer
  layout 'email'

  # Sends and email for indicating a new message or a reply to a receiver.
  # It calls new_message_email if notifing a new message and reply_message_email
  # when indicating a reply to an already created conversation.
  def send_email(mailboxer_message, receiver)
    if mailboxer_message.conversation.messages.size > 1
      reply_message_email(mailboxer_message, receiver)
    else
      new_message_email(mailboxer_message, receiver)
    end
  end

  # Sends an email for indicating a new message for the receiver
  def new_message_email(mailboxer_message, receiver)
    @message  = mailboxer_message
    @receiver = receiver
    set_subject(mailboxer_message)
    mail to: receiver.send(Mailboxer.email_method, mailboxer_message),
         subject: t('mailboxer.message_mailer.subject_new', user_name: mailboxer_message.sender.public_display_name,
                                                            subject: @subject),
         template_name: 'new_message_email'
  end

  # Sends and email for indicating a reply in an already created conversation
  def reply_message_email(mailboxer_message, receiver)
    @message  = mailboxer_message
    @receiver = receiver
    set_subject(mailboxer_message)
    mail to: receiver.send(Mailboxer.email_method, mailboxer_message),
         subject: t('mailboxer.message_mailer.subject_reply', user_name: mailboxer_message.sender.public_display_name,
                                                              subject: @subject),
         template_name: 'reply_message_email'
  end

  def new_requested_time(mailboxer_message, receiver)
    @message  = mailboxer_message
    @receiver = receiver
    set_subject(mailboxer_message)
    mail to: receiver.send(Mailboxer.email_method, mailboxer_message),
         subject: @subject,
         template_name: __method__
  end

  def new_requested_session(mailboxer_message, receiver)
    @message  = mailboxer_message
    @receiver = receiver
    set_subject(mailboxer_message)
    mail to: receiver.send(Mailboxer.email_method, mailboxer_message),
         subject: @subject,
         template_name: __method__
  end
end
