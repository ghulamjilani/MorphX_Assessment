# frozen_string_literal: true

class PayoutMailer < ApplicationMailer
  include Devise::Mailers::Helpers
  layout 'email'

  def payout_done(params, user)
    @params = params
    @user = user

    mail(
      to: csr_recipient_emails,
      subject: "Payout Done on #{Rails.env}"
    )
  end

  def payout_failed(data, user)
    @data = data
    @user = user
    mail(
      to: csr_recipient_emails,
      subject: "Payout Failed on #{Rails.env}"
    )
  end
end
