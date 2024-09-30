# frozen_string_literal: true

module HelpHelper
  def help_icon(category_name)
    case category_name.to_s
    when 'general'
      'settings'
    when 'account'
      'docF'
    when 'payments', 'rewards_program'
      'dollarF'
    when 'channels_and_sessions'
      'chat-emptyF'
    when 'cancellation_policy'
      'cross'
    else
      raise ArgumentError, category_name
    end
  end

  def faq_presenters
    @faq_presenters ||= begin
      raw = I18n.backend.translations[:en][:faq][:for_presenters]
      result                              = {}
      result[:general]                    = raw[:general]
      result[:account]                    = raw[:account]
      result[:payments]                   = raw[:payments]
      result[:channels_and_sessions] = raw[:channels_and_sessions]
      result[:cancellation_policy] = raw[:cancellation_policy]

      result
    end
  end

  def faq_participants
    @faq_participants ||= begin
      raw = I18n.backend.translations[:en][:faq][:for_users]
      result                              = {}
      result[:general]                    = raw[:general]
      result[:account]                    = raw[:account]
      result[:rewards_program]            = raw[:rewards_program]
      result[:payments]                   = raw[:payments]

      if raw[:channels_and_sessions].present?
        result[:channels_and_sessions] = raw[:channels_and_sessions]
      end

      result
    end
  end

  def faq_replacements
    @faq_replacements ||= {
      service_name: Rails.application.credentials.global[:service_name].to_s,
      support_email: Rails.application.credentials.global[:support_mail].to_s
    }
  end
end
