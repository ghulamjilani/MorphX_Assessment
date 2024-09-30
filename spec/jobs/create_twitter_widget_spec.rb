# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe CreateTwitterWidget do
  pending 'something went wrong'
  # let(:session) { create(:immersive_session, twitter_feed_title: 'hashtag') }
  # it 'works' do
  #   allow_any_instance_of(TwitterWidget).to receive(:get_widget_id).and_return("123")
  #   expect_any_instance_of(TwitterWidget).to receive(:get_widget_id)
  #   Sidekiq::Testing.inline! do
  #     CreateTwitterWidget.perform_async(session.id)
  #   end
  #
  #
  #   session.reload
  #   expect(session.twitter_feed_widget_id).to eq("123")
  #   expect(session.twitter_feed_href).to eq("https://twitter.com/hashtag/#{CGI.escape(session.twitter_feed_title)}")
  # end
  #
  # it 'send email if failed' do
  #   allow_any_instance_of(TwitterWidget).to receive(:get_widget_id).and_raise
  #   expect(Mailer).to receive_message_chain(:twitter_widget_create_failed, :deliver)
  #   Sidekiq::Testing.inline! do
  #     CreateTwitterWidget.perform_async(session.id)
  #   end
  # end
end
