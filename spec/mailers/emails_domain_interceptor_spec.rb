# frozen_string_literal: true

require 'spec_helper'

describe 'EmailsDomainInterceptor' do
  let(:mailer) do
    ActionMailer::Base.mail(to: to, from: from, subject: 'test', body: 'test').deliver
  end

  let(:from) { 'no-reply@example.com' }

  context 'when email "to:" domain is not forbidden' do
    let(:to) { 'user@example.com' }

    it 'sends emails' do
      expect { mailer }.to change(ActionMailer::Base.deliveries, :count)
    end
  end

  context 'when email "to:" domain is forbidden' do
    let(:to) { 'user@somexemail.com' }

    it 'does not send emails' do
      expect { mailer }.not_to change(ActionMailer::Base.deliveries, :count)
    end
  end
end
