# frozen_string_literal: true

class CreateRecurringSession
  @queue = 'high'

  def self.perform(session:)
    if (children = session.children.first)
      children.destroy
    end

    settings = session.recurring_settings
    if settings[:active].present?
      days_of_week = settings[:days].is_a?(Array) ? settings[:days] : Session::DAYS_OF_WEEK
      start_times = []
      (1..150).each do |i|
        current_time = session.start_at + i.day
        if settings[:until] == 'date'
          break if current_time > Date.strptime(settings[:date], '%m/%d/%Y')
        elsif start_times.count >= settings[:occurrence].to_i
          break
        end

        start_times << current_time if days_of_week.include?(current_time.strftime('%A').downcase)
      end

      current_session = session
      Session.transaction do
        start_times.each do |start_at|
          children = current_session.dup
          if current_session.cover.try(:file)
            children.cover = current_session.cover.file
          end
          children.uuid = SecureRandom.uuid
          children.skip_cover_validation = true
          children.recurring_id = current_session.id
          children.start_at = start_at
          children.start_now = false
          children.short_url = nil
          children.referral_short_url = nil
          children.save!
          current_session = children
        end
      end
    end
  end
end
