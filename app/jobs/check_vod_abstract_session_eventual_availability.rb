# frozen_string_literal: true

# if user checked "VOD" delivery method during session creation
# our responsibility is to deliver this video(eventually, with some delay)
# if it fails to deliver automatically then at least notify everyone involved
# so that we can handle it manually or not wait until angry customer writes
# to support
class CheckVodAbstractSessionEventualAvailability < ApplicationJob
  def perform(abstract_session_type, abstract_session_id)
    abstract_session = abstract_session_type.constantize.find(abstract_session_id)

    abstract_session.update_attribute(:eventual_vod_availability_check_count,
                                      abstract_session.eventual_vod_availability_check_count + 1)

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
      Rails.logger.info "abstract session #{abstract_session.inspect} does not have VOD delivery method, skipping vod_is_fully_ready statuc check"
      return
    end

    room = abstract_session.room
    if room.present? && room.room_members.pluck(:joined).any? && room.vod_is_fully_ready != true

      ::Mailer.vod_didnt_became_available_on_time(abstract_session).deliver_now
    end
  end
end
