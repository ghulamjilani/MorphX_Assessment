# frozen_string_literal: true

class ProgressBar
  def initialize(total, day)
    @total   = total
    @day     = day
    @counter = 1
  end

  def increment
    complete = sprintf('%#.2f%%', ((@counter.to_f / @total.to_f) * 100))
    print "\r\e[0K#{@day.inspect}"
    print "\r\e[0K#{@counter}/#{@total} (#{complete})"
    @counter += 1
  end
end

module Immerss
  class DemoLikeSessionsGenerator
    def initialize(day = 1.day.from_now, daily_sessions_needed_count = 65)
      @day                         = day
      @daily_sessions_needed_count = daily_sessions_needed_count
    end

    def perform
      daily_sessions_count = Session.not_cancelled.is_public.published.where('start_at > ? AND start_at < ?',
                                                                             @day.beginning_of_day, @day.end_of_day).count

      progress_bar = ProgressBar.new(@daily_sessions_needed_count - daily_sessions_count, @day)

      loop do
        begin
          max_slots = (23 * 60) / 15
          start_at = (15 * rand(max_slots)).minutes.since @day.beginning_of_day
          channel = pick_or_create_random_channel

          type_of_session = %i[
            free_trial_immersive_session
            completely_free_session
            immersive_session
            immersive_session_with_recorded_delivery
            session_with_livestream_only_delivery
            one_on_one_session
            recorded_session
          ].sample

          session = FactoryBot.build(type_of_session,
                                     title: session_title_sample_by_channel_title(channel.title),
                                     start_at: start_at,
                                     custom_description_field_value: session_custom_description_field_value_sample_by_channel_title(channel.title),
                                     channel: channel,
                                     presenter_id: channel.available_presenter_ids.first)
          raise session.errors.full_messages.inspect unless session.valid?

          session.save!

          session.status = 'published'
          session.save!

          daily_sessions_count += 1
          progress_bar.increment
        rescue NoMethodError => e
          raise e
        rescue StandardError => e
          unless e.message.include?('tart')
            puts e.message
            puts e.backtrace
          end
          # puts e.class
          # puts "#{start_at.inspect} #{e.message}"
        end
        break unless daily_sessions_count < @daily_sessions_needed_count
      end
    end

    private

    def session_title_sample_by_channel_title(_channel_title)
      "#{Forgery::Name.company_name} #{Forgery::Name.location} #{rand(400)}"
    end

    def session_custom_description_field_value_sample_by_channel_title(_channel_title)
      Forgery(:lorem_ipsum).paragraphs(2)
    end

    def pick_or_create_random_channel
      Channel.where(show_on_home: false).not_archived.where.not(listed_at: nil).sample || FactoryBot.create(
        :approved_channel_with_image, organization: Organization.all.sample
      )
    end
  end
end
