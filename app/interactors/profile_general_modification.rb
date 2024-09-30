# frozen_string_literal: true

class ProfileGeneralModification
  def initialize(current_user)
    @current_user = current_user
  end

  def execute
    email_changed   = @current_user.email_changed?

    ActiveRecord::Base.transaction do
      if @current_user.email_was.blank?
        @current_user.skip_reconfirmation!
      end
      if @current_user.valid?
        if @current_user.save
          if email_changed
            @flash_message_text = 'You will receive an email with instructions about how to change your email in a few minutes.'
            @redirect_to_path = 'edit_general_profile_path'
          else
            @redirect_to_path = 'edit_general_profile_path'
          end
        else
          false
        end
      else
        Rails.logger.debug @current_user.errors.full_messages
        false
      end
    end
  end

  attr_reader :flash_message_text, :redirect_to_path
end
