# frozen_string_literal: true

class FreeSubscriptions::Create < ApplicationJob
  def perform(first_name, last_name, email, channel_id, duration_in_months)
    return if email.blank?

    channel = ::Channel.find(channel_id)
    user = channel.organization.user
    invited_user = ::User.find_by(email: email.to_s.strip.downcase) if email
    if invited_user.blank?
      invited_user = ::User.invite!(
        { email: email, first_name: first_name, last_name: last_name }, user
      ) do |u|
        u.before_create_generic_callbacks_and_skip_validation
        u.skip_invitation = true
      end
    end
    return if channel.free_subscriptions.in_action.exists?(user: invited_user)

    unless (free_plan = ::FreePlan.not_archived.find_by(channel: channel, duration_type: 'duration_fixed', duration_in_months: duration_in_months))
      name = "#{channel.title}, #{duration_in_months} months"
      free_plan = ::FreePlan.create!(name: name, channel: channel, duration_type: 'duration_fixed', duration_in_months: duration_in_months)
    end

    FreeSubscription.create(
      free_plan:,
      user: invited_user,
      start_at: Time.now.utc,
      end_at: duration_in_months.to_i.months.from_now
    )
  end
end
