# frozen_string_literal: true

module ModelConcerns::User::ActsAsAppleUser
  extend ActiveSupport::Concern

  module ClassMethods
    def connect_to_apple(payload)
      if (user = where(email: payload.info.email).first)
        user.connect_apple(payload)
        user
      end
    end

    def apple_attributes_to_assign_from_payload(payload)
      {
        display_name: "#{payload.info.first_name} #{payload.info.last_name}",
        first_name: payload.info.first_name,
        last_name: payload.info.last_name
      }
    end

    def create_from_apple(payload)
      user = new
      user.attributes = apple_attributes_to_assign_from_payload(payload)
      user.email = payload.info.email
      user.tzinfo = payload.tzinfo

      user.before_create_generic_callbacks_and_skip_validation

      # otherwise it is treated as confirmed account despite blank email
      if user.email.present?
        user.skip_confirmation!
      else
        user.skip_validation_for :email
      end
      # Skip password validation
      def user.password_required?
        false
      end

      user.save!

      user.identities.create!(provider: payload.provider, uid: payload.uid)

      user
    end
  end
end
