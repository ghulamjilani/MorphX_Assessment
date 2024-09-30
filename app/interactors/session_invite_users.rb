# frozen_string_literal: true

class SessionInviteUsers
  def initialize(session:,
                 current_user:,
                 invited_users_attributes:)

    @session                  = session
    @current_user             = current_user
    @invited_users_attributes = invited_users_attributes

    emails1 = @invited_users_attributes.select { |h| h[:add_as_contact] }.pluck(:email)
    @add_as_contacts_emails = emails1
  end

  # return [Boolean] - true if succeeded, otherwise false
  def execute
    SessionJobs::EditInvitedUsersJob.perform_async(@session.id, @current_user.id, @invited_users_attributes)
    UserJobs::AddContactUsersJob.perform_async(@current_user.id, @add_as_contacts_emails)
  rescue StandardError => e
    false
  end

  attr_reader :session
end
