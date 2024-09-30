# frozen_string_literal: true

module ModelConcerns::User::ActsAsFacebookUser
  extend ActiveSupport::Concern

  def save_facebook_friends(payload)
    return if payload.credentials.blank?

    if (token = payload.credentials.token)
      graph = Koala::Facebook::API.new(token)
      begin
        if (friends = graph.get_connections('me', 'friends').to_a)
          # friends.inspect
          # [
          #  {"name" => "Peter Gabbay", "id" => "2535244"},
          #  {"name" => "Azis Abakirov", "id" => "516024524"},
          #  {"name" => "Andrew 'Senza' Cox", "id" => "542046804"},
          #  {"name" => "Chinara Isabaeva", "id" => "579847743"},
          #  {"name" => "Michael Romanenko", "id" => "613763765"},
          #  {"name" => "Nina Litvinova", "id" => "625778813"},
          #  {"name" => "Philippe Lafoucrière", "id" => "633932425"}
          # ]

          update_attribute(:facebook_friends, friends)

          # TODO: move this to background job eventually.
          #      right now we just need this without performance so that Facebook can review/verify our submitted app.
          User.where.not(id: id, facebook_friends: nil).each do |other_user|
            if other_user.facebook_friends.any? do |hash|
                 hash.symbolize_keys[:id].to_s == payload.uid.to_s
               end
              # user_is_facebook_friend_for_.inspect
              #=> [{"name" => "John Brown", "id" => "10000829236144"}]

              # not valid in cause contact is already present
              Contact.new(for_user: other_user,
                          originally_facebook_friend_and_not_seen_yet: true,
                          contact_user: self,
                          email: email,
                          name: public_display_name).tap { |c| c.save! if c.valid? }
              Contact.new(for_user: self,
                          originally_facebook_friend_and_not_seen_yet: true,
                          contact_user: other_user,
                          email: other_user.email,
                          name: other_user.public_display_name).tap { |c| c.save! if c.valid? }
            end
          end
        end
      rescue Koala::Facebook::ServerError => e
        Rails.logger.info e.message
        Airbrake.notify(e,
                        parameters: {
                          user: inspect,
                          payload: payload.to_hash,
                          friends: friends.inspect
                        })
      end
    else
      raise "blank token: #{payload.credentials}"
    end
  end

  module ClassMethods
    def connect_to_facebook(payload)
      if (user = where(email: payload.info.email).first)
        user.connect_facebook(payload)

        if user.image.blank?
          res = Net::HTTP.get_response(URI("http://graph.facebook.com/#{payload.uid}/picture?type=large"))

          i = user.build_image
          i.remote_original_image_url = res['location']
          i.save(validate: false)
        end

        user
      end
    end

    def facebook_attributes_to_assign_from_payload(payload)
      gender = if [User::Genders::MALE, User::Genders::FEMALE,
                   User::Genders::HIDDEN].include?(payload.extra.raw_info.gender)
                 payload.extra.raw_info.gender
               else
                 nil
               end
      {
        first_name: payload.extra.raw_info.first_name,
        last_name: payload.extra.raw_info.last_name,
        display_name: payload.extra.raw_info.name,
        gender: gender
      }
    end

    def create_from_facebook(payload)
      user = new
      user.attributes = facebook_attributes_to_assign_from_payload(payload)

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

      if user.image.blank?
        res = Net::HTTP.get_response(URI("http://graph.facebook.com/#{payload.uid}/picture?type=large"))

        i = user.build_image
        i.remote_original_image_url = res['location']
        i.save(validate: false)
      end

      token = nil
      expires = nil
      expires_at = nil
      if payload.credentials.present?
        token = payload.credentials.token
      end
      if payload.credentials.present?
        expires = payload.credentials.expires
      end
      if payload.credentials.present? && payload.credentials.expires_at.present?
        expires_at = Time.at(payload.credentials.expires_at)
      end

      user.identities.create!(provider: payload.provider,
                              uid: payload.uid,
                              token: token,
                              expires: expires,
                              expires_at: expires_at)

      user
    end
  end
end
