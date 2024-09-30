# frozen_string_literal: true

module Api
  module V1
    module Public
      class SupportMessagesController < Api::V1::Public::ApplicationController
        include ControllerConcerns::ValidatesRecaptcha

        def contact_us
          unless recaptcha_verified?(:support_contact_us)
            raise ArgumentError, Recaptcha::Helpers.to_error_message(:verification_failed)
          end

          params.require(:first_name)
          params.require(:email)
          params.require(:about)

          Mailer.lets_talk(
            params.permit(:name, :company, :first_name, :last_name, :email, :phone, :about)
          ).deliver_now
          head :ok
        end
      end
    end
  end
end
