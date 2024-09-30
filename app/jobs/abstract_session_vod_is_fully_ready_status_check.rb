# frozen_string_literal: true

class AbstractSessionVodIsFullyReadyStatusCheck < ApplicationJob
  def perform(abstract_session_type, abstract_session_id, error_count = 0)
    abstract_session = abstract_session_type.constantize.find(abstract_session_id)

    unless abstract_session.finished?
      message = "can not run vod_is_fully_ready status check job for not finished abstract session - #{abstract_session.inspect}"
      Rails.logger.info message

      if Rails.env.development? # because otherwise db:seed fails #TODO - is there a better way?
        return
      end

      if Rails.env.qa? || Rails.env.production?
        raise message
        return
      end
    end

    if abstract_session.cancelled?
      Rails.logger.info "abstract session #{abstract_session.inspect} is cancelled, skipping vod_is_fully_ready status check"
      return
    end

    unless abstract_session.recorded_delivery_method?
      Rails.logger.info "abstract session #{abstract_session.inspect} does not have VOD delivery method, skipping vod_is_fully_ready status check"
      return
    end

    unless PendingVodAvailabilityMembership.where(abstract_session: abstract_session).count.positive?
      Rails.logger.info "abstract session #{abstract_session.inspect} does not have PendingVodAvailabilityMembership, skipping vod_is_fully_ready status check"
      return
    end

    if error_count.to_i > 480 # 5 days, each 15 mins
      Airbrake.notify_sync(RuntimeError.new('AbstractSessionVodIsFullyReadyStatusCheck users wants see notification, please fix me'),
                           parameters: { abstract_session_type: abstract_session_type,
                                         abstract_session_id: abstract_session_id })
      return
    end

    if abstract_session.room.vod_is_fully_ready == false or abstract_session.room.vod_is_fully_ready.nil?
      AbstractSessionVodIsFullyReadyStatusCheck.perform_at(15.minutes.from_now, abstract_session_type,
                                                           abstract_session_id, error_count += 1)

    elsif abstract_session.room.vod_is_fully_ready == true && abstract_session.vod_waiting_list_is_notified != true

      PendingVodAvailabilityMembership.where(abstract_session: abstract_session).each do |membership|
        ::Mailer.vod_just_became_available_for_purchase(membership.user_id, abstract_session).deliver_later
      end

      abstract_session.update_attribute(:vod_waiting_list_is_notified, true)
    end
  end
end
