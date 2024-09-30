# frozen_string_literal: true

# require Rails.root.join('lib/twitter/twitter_widget').to_s

class CreateTwitterWidget < ApplicationJob
  def perform(session_id)
    session = Session.find(session_id)
    widget_id = TwitterWidget.new(session.twitter_feed_title).get_widget_id
    session.twitter_feed_widget_id = widget_id
    session.twitter_feed_href = "https://twitter.com/hashtag/#{CGI.escape(session.twitter_feed_title)}"
    session.save!
  rescue StandardError => e
    Rails.logger.debug e.inspect
    Mailer.twitter_widget_create_failed(session_id).deliver
  end
end
