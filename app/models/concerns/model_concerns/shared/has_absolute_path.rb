# frozen_string_literal: true

module ModelConcerns::Shared::HasAbsolutePath
  # !!!REQUIRES #relative_path method to be defined

  extend ActiveSupport::Concern

  included do
    # utm_params are needed for tracking visits from email links
    # @see UTM dependency
    # refc_user for sharing
    # @see SharingHelper, SharedControllerHelper
    def absolute_path(utm_params = nil, refc_user = nil)
      request_protocol = ActionMailer::Base.default_url_options[:protocol] || 'http://'
      host             = ActionMailer::Base.default_url_options[:host] or raise 'cant get HOST'

      result = "#{request_protocol}#{host}#{relative_path}"

      unless result&.match?(URI::DEFAULT_PARSER.make_regexp)
        raise "check your protocol/host env properties - invalid URL format for session - #{result} ; #{request_protocol} ; #{host}"
      end

      params = []
      params << utm_params if utm_params
      params << "refc=#{refc_user.my_referral_code_text}" if refc_user.is_a?(User)
      result += "?#{params.join('&')}" unless params.empty?
      result
    end
  end
end
