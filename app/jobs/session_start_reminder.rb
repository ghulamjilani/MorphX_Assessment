# frozen_string_literal: true

class SessionStartReminder < ApplicationJob
  def perform(session_id, user_id, policy_klass)
    user = User.find_by(id: user_id)
    return true unless user

    session = Session.find_by(id: session_id)
    return true unless user

    if AbilityLib::SessionAbility.new(user).can?(:receive_session_start_reminders, session)
      Immerss::SessionMultiFormatMailer.new(policy_klass).start_reminder(session_id, user_id).deliver
    else
      Rails.logger.info "Skipping session start reminder for user #{user_id}"
    end
  end
end
