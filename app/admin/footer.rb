# frozen_string_literal: true

module ActiveAdmin
  module Views
    class Footer < Component
      def build(_namespace)
        super id: 'footer'
        super style: 'font-size: 1.2em;'
        time_now = Time.now
        div do
          'Current server time:'
        end
        div do
          utc_and_admin_time_formatted(Time.now.utc)
        end
        div do
          time_now.to_i
        end
      end
    end
  end
end
