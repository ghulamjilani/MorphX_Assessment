# frozen_string_literal: true

class BlockableMailer < ApplicationMailer
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::UrlHelper

  include Devise::Mailers::Helpers

  def content_blocked(model_type, model_id)
    @model = model_type.constantize.find(model_id)
    @users = [@model.organizer, @model.channel.organization.user].flatten.uniq
    @model_type = case model_type
                  when 'Recording'
                    'Upload'
                  when 'Video'
                    'Replay'
                  else
                    model_type
                  end
    @subject = "#{@model_type} blocked"

    ::Immerss::Mailboxer::Notification.save_with_receipt(
      user: @model.organizer,
      subject: @subject,
      sender: nil,
      body: render_to_string(__method__, layout: false)
    )

    mail(to: @users.map(&:email), subject: @subject)
  end
end
