# frozen_string_literal: true

module ModelConcerns::User::ActsAsInstagramUser
  extend ActiveSupport::Concern

  module ClassMethods
    def connect_to_instagram(payload)
      if (user = Identity.where(provider: payload.provider, uid: payload.uid).first.try(:user))
        user.connect_instagram(payload)

        if user.image.blank? && payload[:info][:image].present?
          i = user.build_image
          i.remote_original_image_url = payload[:info][:image]
          i.save(validate: false)
        end

        user
      end
    end

    def instagram_attributes_to_assign_from_payload(payload)
      if payload.info.name.include?(' ')
        first_name = payload.info.name.split(' ').first
        last_name = payload.info.name.split(' ').last
      else
        first_name = payload.info.name
        last_name = nil
      end

      {
        first_name: first_name,
        last_name: last_name,
        display_name: payload.info.nickname
      }
    end

    def create_from_instagram(payload)
      # {
      #     provider: "instagram",
      #     uid: "570844723",
      #     info: {
      #         nickname: "stdashulya",
      #         name: "Darina Varankover",
      #         image: "https://scontent.cdninstagram.com/t51.2885-19/10986321_783517631740431_1937657712_a.jpg",
      #         bio: "",
      #         website: "",
      #         is_business: false
      #     },
      #     credentials: {
      #         token: "570844723.5ddc52e.31326d4ea1bb4f1a9c263c5a6e7f011d",
      #         expires: false
      #     },
      #     extra: {
      #         raw_info: {
      #             id: "570844723",
      #             username: "stdashulya",
      #             profile_picture: "https://scontent.cdninstagram.com/t51.2885-19/10986321_783517631740431_1937657712_a.jpg",
      #             full_name: "Darina Varankover",
      #             bio: "",
      #             website: "",
      #             is_business: false
      #         }
      #     }
      # }
      #

      user = new
      user.attributes = instagram_attributes_to_assign_from_payload(payload)
      user.tzinfo = payload.tzinfo

      if payload.info.email.present?
        user.email = payload.info.email

        user.skip_validation_for(*all_validation_skipable_user_attributes.dup.reject { |s| s == :email })
      else
        user.skip_validation_for(*all_validation_skipable_user_attributes)
      end
      user.before_create_generic_callbacks_without_skipping_validation

      # otherwise it is treated as confirmed account despite blank email
      if user.email.present?
        user.skip_confirmation!
      end
      # Skip password validation
      def user.password_required?
        false
      end

      user.save!

      user.identities.create!(provider: payload.provider,
                              uid: payload.uid,
                              expires: payload.credentials.expires,
                              expires_at: payload.credentials.expires_at,
                              token: payload.credentials.token,
                              secret: payload.credentials.secret || payload.credentials.refresh_token)

      if user.image.blank? && payload[:info][:image].present?
        i = user.build_image
        i.remote_original_image_url = payload[:info][:image]
        i.save(validate: false)
      end

      user
    end
  end
end
