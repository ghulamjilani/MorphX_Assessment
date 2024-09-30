# frozen_string_literal: true

class FindNonCorrectRecords < ApplicationJob
  def perform(*_args)
    debug_logger(:start)
    presenters = Presenter.select('presenters.id, presenters.user_id')
                          .joins('LEFT JOIN users ON users.id = presenters.user_id').where(users: { id: nil })
    if presenters.exists?
      maps = presenters.pluck(:id).map(&:to_s)
      if maps != ResqueApi.redis.get(:find_non_correct_records).to_s
        Airbrake.notify_sync(RuntimeError.new('User was removed incorrect'),
                             parameters: { presenters: presenters.inspect, time_now: Time.now.utc })
        ResqueApi.redis.set(:find_non_correct_records, maps)
      end
    end
  end
end
