# frozen_string_literal: true

class EmailsDomainInterceptor
  def self.delivering_email(message)
    unless deliver?(message)
      message.perform_deliveries = false
      Rails.logger.debug "Interceptor prevented sending mail #{message.inspect}!"
    end
  end

  def self.deliver?(message)
    forbidden_domains = ['somexemail.com']

    forbidden_domains_regexp = /#{forbidden_domains.map { |domain| "(#{Regexp.escape(domain.downcase)})" }.join('|')}/
    message.to.find { |recipient| recipient.downcase =~ forbidden_domains_regexp }.blank?
  end
end
