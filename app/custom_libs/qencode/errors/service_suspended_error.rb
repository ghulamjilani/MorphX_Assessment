# frozen_string_literal: true

module Qencode
  module Errors
    class ServiceSuspendedError < ::Qencode::Errors::Error
      def message
        I18n.t('custom_libs.qencode.errors.service_suspended_error.message')
      end
    end
  end
end
