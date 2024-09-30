# frozen_string_literal: true

module ModelConcerns::User::ActsAsLinkedinUser
  extend ActiveSupport::Concern

  module ClassMethods
    def connect_to_linkedin(payload)
      if (user = where(email: payload.info.email).first)
        user.connect_linkedin(payload)

        if user.image.blank? && payload.info.image.present?
          i = user.build_image
          i.remote_original_image_url = payload.info.image
          i.save(validate: false)
        end

        user
      end
    end

    def linkedin_attributes_to_assign_from_payload(payload)
      {
        first_name: payload.info.first_name,
        last_name: payload.info.last_name,
        display_name: payload.info.nickname
      }
    end

    def create_from_linkedin(payload)
      # payload.inspect
      #=> {"provider" => "linkedin",
      # "uid" => "u3Tm-BPoe_",
      # "info"=>
      #  {"name" => "Nikita Fedyashev",
      #   "email" => "nfedyashev@gmail.com",
      #   "nickname" => "Nikita Fedyashev",
      #   "first_name" => "Nikita",
      #   "last_name" => "Fedyashev",
      #   "location"=>nil,
      #   "description"=>nil,
      #   "image"=>
      #    "http://m.c.lnkd.licdn.com/mpr/mprx/0_x9J4Kt9SerQuyfFtgnUwKAlTelATpfntjADbKAnPBcLliwT-1rdqOlGgQylYxHBYYzR6xnH7OLin",
      #   "phone"=>nil,
      #   "headline"=>nil,
      #   "industry"=>nil,
      #   "urls"=>{"public_profile" => "http://www.linkedin.com/in/nfedyashev"}},
      # "credentials"=>
      #  {"token" => "f33f5f4c-bad1-4ebe-a65b-5ff9391a08aa",
      #   "secret" => "c0fe6fef-75dc-43ab-857d-be479b881f5a"},
      # "extra"=>

      user = new
      user.attributes = linkedin_attributes_to_assign_from_payload(payload)
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

      if user.image.blank? && payload.info.image.present?
        i = user.build_image
        i.remote_original_image_url = payload.info.image
        i.save(validate: false)
      end

      token = nil
      if payload.credentials.present?
        token = payload.credentials.token
      end

      # looks like we don't need s secret
      # secret = nil
      # if payload.credentials.present?
      #  secret = payload.credentials.secret
      # end

      user.identities.create!(provider: payload.provider,
                              uid: payload.uid,
                              token: token)

      user
    end
  end
end
