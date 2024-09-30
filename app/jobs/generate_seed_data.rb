# frozen_string_literal: true

class GenerateSeedData < ApplicationJob
  def perform(*_args)
    if Rails.env.production?
      Rails.logger.info 'GenerateSeedData is skipped in production'
      return
    end

    # NOTE: it is important - otherwise hundreds of emails would be sent
    # your contact published a session(there are a lot of contacts on qa!)
    original_status = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false

    generate_organizations
    generate_sessions
    generate_reviews_for_passed_sessions

    ActionMailer::Base.perform_deliveries = original_status
  rescue ActiveRecord::RecordInvalid
    # don't raise errors in Airbrake
    true
  end

  private

  def generate_organizations
    # fetch from existing users rather than creating new ones
    # TODO - you may want to make it more intelligent to choose only users without orgs in this lambda block
    _lambda = -> { User.all.sample }

    generate_real_looking_organization 2.times, _lambda
  end

  def generate_sessions
    daily_sessions_needed_count = case Rails.env.to_s
                                  when 'test'
                                    5
                                  when 'qa'
                                    25
                                  when 'development'
                                    35
                                  else
                                    raise ArgumentError, Rails.env.to_s
                                  end

    # 2 weeks is hard limit of how far you can schedule
    Immerss::DemoLikeSessionsGenerator.new(13.days.from_now, daily_sessions_needed_count).perform
  end

  def generate_reviews_for_passed_sessions
    sessions = Session
               .joins('LEFT OUTER JOIN channels ON channels.id = sessions.channel_id')
               .finished
               .not_cancelled
               .where('sessions.immersive_purchase_price IS NOT NULL OR sessions.livestream_purchase_price IS NOT NULL')
               .where('channels.listed_at IS NOT NULL')
               .published
               .limit(4)

    sessions.each do |session|
      rand(12 + 1).times do
        user = User.all.sample

        create_mandatory_rates user, session
        if [true, false].sample
          comment = [
            'looks really good',
            'that was very exciting',
            "I'm impressed",
            'That presenter knows what he is talking about',
            'cant wait to see the next session',
            'Totally recommended!',
            'Best anyone could ask for',
            'Great session',
            'My recommendation !!!',
            'Proof style and substance can go together',
            'perfection',
            'Amazing ending',
            'Wonderful experience',
            'Warmly recommended'
          ].sample

          begin
            Comment.create!(commentable: session, user: user, title: '', overall_experience_comment: comment)
          rescue ActiveRecord::RecordInvalid => e
            puts e.message
          end

        end
      end
    end
  end
end
