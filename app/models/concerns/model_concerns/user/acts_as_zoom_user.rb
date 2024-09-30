# frozen_string_literal: true

module ModelConcerns::User::ActsAsZoomUser
  extend ActiveSupport::Concern

  module ClassMethods
    def zoom_attributes_to_assign_from_payload(payload)
      {
        display_name: "#{payload.extra.raw_info.first_name} #{payload.extra.raw_info.last_name}",
        first_name: payload.extra.raw_info.first_name,
        last_name: payload.extra.raw_info.last_name
      }
    end

    def create_from_zoom(payload)
      user = new
      user.attributes = zoom_attributes_to_assign_from_payload(payload)
      user.email = payload.extra.raw_info.email

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

      user.identities.create!(provider: payload.provider, uid: payload.uid, token: payload.credentials.refresh_token)

      user
    end

    def connect_zoom(payload)
      identity = identities.where(provider: payload.provider).first

      if identity.present?
        if identity.uid != payload.uid
          identity.update_attribute(uid: payload.uid)
        end
      else
        identities.create!(
          provider: payload.provider,
          uid: payload.uid,
          token: payload.credentials.refresh_token
        )
      end
    end
  end
end
