# frozen_string_literal: true

module MailerConcerns::MailboxerHelper
  extend ActiveSupport::Concern

  private

  def strip_tags(text)
    ::Mailboxer::Cleaner.instance.strip_tags(text)
  end
end
