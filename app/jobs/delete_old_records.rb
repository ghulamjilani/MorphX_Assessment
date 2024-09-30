# frozen_string_literal: true

# reason for this job to exist is to "speed up" qa
# and delete excessive number of sessions that would never happen
# with real users
class DeleteOldRecords < ApplicationJob
  def perform(*_args)
    if Rails.env.production?
      Rails.logger.info 'DeleteOldRecords is skipped in production'
      return
    end

    system_user_ids = SystemUser.all.map(&:user_id)
    users = User.where.not(id: system_user_ids).where('last_sign_in_at < :time', { time: 5.months.ago })

    users.find_each(&:destroy!)
    Rails.logger.info "#{users.size} old users have been deleted on #{Rails.env}"
    cleanup_presenter(:users)

    if Rails.env.qa?
      Rails.logger.info 'DeleteOldRecords is now skipped in QA too'
      return
    end

    organizations = Organization.where('updated_at < :time', { time: 1.months.ago })
    organizations.each(&:destroy!)
    Rails.logger.info "#{organizations.size} old organizations have been deleted on #{Rails.env}"
    cleanup_presenter(:organizations)

    channels = Channel.without_sessions.where('created_at < :time', { time: 2.months.ago })
    channels.each(&:destroy!)
    Rails.logger.info "#{channels.size} old channels have been deleted on #{Rails.env}"
    cleanup_presenter(:channels)

    # NOTE: condition was approved by Alex
    sessions = Session.where('created_at < :time', { time: 1.month.ago })
    sessions.each(&:destroy!)
    Rails.logger.info "#{sessions.size} old sessions have been deleted on #{Rails.env}"
    cleanup_presenter(:sessions)

    Rails.cache.clear
  end

  def cleanup_presenter(after)
    presenters = Presenter.select('presenters.id, presenters.user_id')
                          .joins('LEFT JOIN users ON users.id = presenters.user_id').where(users: { id: nil })
    if presenters.exists?
      Airbrake.notify_sync(RuntimeError.new("User was removed incorrect after #{after}"),
                           parameters: { presenters: presenters.inspect, time_now: Time.now.utc })
      presenters.destroy_all
    end
  end
end
