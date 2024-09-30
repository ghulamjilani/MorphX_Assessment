# frozen_string_literal: true

module Usage
  class Event
    module Types
      INTERACTIVE_TIME = 'interactive_time'
      INTERACTIVE_BANDWIDTH = 'interactive_bandwidth'

      LIVESTREAM_TIME = 'livestream_time'
      LIVESTREAM_BANDWIDTH = 'livestream_bandwidth'

      PLAYBACK_TIME = 'playback_time'
      PLAYBACK_BANDWIDTH = 'playback_bandwidth'

      REWIND_TIME = 'rewind_time'
      PAUSE_TIME = 'pause_time'

      ALL = [
        INTERACTIVE_TIME,
        INTERACTIVE_BANDWIDTH,
        LIVESTREAM_TIME,
        LIVESTREAM_BANDWIDTH,
        PLAYBACK_TIME,
        PLAYBACK_BANDWIDTH,
        REWIND_TIME,
        PAUSE_TIME
      ].freeze
    end
  end
end
