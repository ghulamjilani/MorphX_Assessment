# frozen_string_literal: true

module Mailing
  class Template
    GENERAL = {
      id: 'email_general',
      title: I18n.t('dashboard.mailing.templates.general.title'),
      layout: 'email'
    }.freeze

    GENERAL2 = {
      id: 'email2_general',
      title: I18n.t('dashboard.mailing.templates.general2.title'),
      layout: 'email2'
    }.freeze

    GENERAL3 = {
      id: 'email3_general',
      title: I18n.t('dashboard.mailing.templates.general3.title'),
      layout: 'email3'
    }.freeze

    TIME_TO_UNITE = Rails.application.credentials.backend.dig(:mailer, :templates, :time_to_unite) ? {
      id: 'time_to_service',
      title: I18n.t('dashboard.mailing.templates.time_to_service.title',
                    service_name: Rails.application.credentials.global[:service_name]),
      layout: 'email'
    } : nil

    BASIC = [
      GENERAL,
      TIME_TO_UNITE
    ].compact

    ALL = [
      GENERAL,
      GENERAL2,
      GENERAL3,
      TIME_TO_UNITE
    ].compact
  end
end
