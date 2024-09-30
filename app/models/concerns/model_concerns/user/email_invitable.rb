# frozen_string_literal: true

module ModelConcerns::User::EmailInvitable
  extend ActiveSupport::Concern

  class_methods do
    def find_or_invite_by_email(email, invited_by = nil)
      email = email.to_s.downcase
      user = User.find_or_initialize_by(email: email)
      user.valid?

      return nil if user.errors[:email].any?

      if user.new_record?
        user = User.invite!({ email: email }, invited_by) do |u|
          u.before_create_generic_callbacks_and_skip_validation
          u.skip_invitation = true
        end
      end

      user
    end
  end
end
