# frozen_string_literal: true

class MessageMailerPreview < ApplicationMailerPreview
  def new_in_app_message
    MessageMailer.new_message_email(Mailboxer::Message.first, User.all.sample)
  end

  def new_reply_message
    MessageMailer.reply_message_email(Mailboxer::Message.first, User.all.sample)
  end

  def requested_another_time
    obj = RequestAnotherTime.new(requested_at: rand(1..12).hours.from_now)

    if [true, false].sample
      obj.delivery_method = RequestAnotherTime::ImmerssiveTypes::GROUP
    end

    if [true, false].sample
      obj.comment = Forgery(:lorem_ipsum).paragraphs(2)
    end

    obj.current_user = User.all.sample
    obj.session      = Session.all.sample

    receiver = User.all.sample
    MessageMailer.new_requested_time(obj.mailboxer_message, receiver)
  end

  def new_requested_session
    obj = RequestSession.new(requested_at: rand(1..12).hours.from_now)

    if [true, false].sample
      obj.delivery_method = RequestSession::ImmerssiveTypes::GROUP
    end

    if [true, false].sample
      obj.comment = Forgery(:lorem_ipsum).paragraphs(2)
    end

    obj.current_user = User.all.sample
    obj.channel = Channel.all.sample

    receiver = User.all.sample
    MessageMailer.new_requested_session(obj.mailboxer_message, receiver)
  end
end
