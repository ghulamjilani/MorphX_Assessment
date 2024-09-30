# frozen_string_literal: true

class LiveGuideChannelsAggregator
  def initialize(sessions)
    @sessions = sessions
  end

  def self.trigger_live_refresh
    SessionsChannel.broadcast 'force-refresh-live-guide'
  end

  def overlaps?(already_present_session)
    (start_at - already_present_session.end_at) * (already_present_session.start_at - end_at) >= 0
  end

  def result
    @result ||= begin
      accumulator = {}
      @sessions.each do |session|
        channel = 1

        while true
          channel_name = "Channel ##{channel}"
          accumulator[channel_name] = [] if accumulator[channel_name].blank?

          overlaps = accumulator[channel_name].any? do |already_present_session|
            (session.start_at - already_present_session.end_at) * (already_present_session.start_at - session.end_at) >= 0
          end

          if overlaps
            channel += 1
          else
            break
          end
        end

        accumulator[channel_name] << session
      end
      accumulator
    end
  end
end
