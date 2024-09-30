# frozen_string_literal: true

module ModelConcerns::User::ActsAsGplusUser
  extend ActiveSupport::Concern

  module ClassMethods
    def connect_to_gplus(payload)
      if (user = where(email: payload.info.email).first)
        user.connect_gplus(payload)
        user
      end
    end

    def gplus_attributes_to_assign_from_payload(payload)
      {
        display_name: "#{payload.info.first_name} #{payload.info.last_name}",
        first_name: payload.info.first_name,
        last_name: payload.info.last_name
      }
    end

    def create_from_gplus(payload)
      user = new
      user.attributes = gplus_attributes_to_assign_from_payload(payload)
      user.email = payload.info.email
      user.tzinfo = payload.tzinfo

      user.before_create_generic_callbacks_and_skip_validation

      # otherwise it is treated as confirmed account despite blank email
      if user.email.present?
        user.skip_confirmation!
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
