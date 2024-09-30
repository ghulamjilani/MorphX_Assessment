# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::CanWrapExternalUrls do
  # describe '.link_wrapper' do
  #   let(:url) { "#{[true, false].sample ? 'https' : 'http'}://#{Forgery(:internet).domain_name}" }
  #   let(:url2) { "#{[true, false].sample ? 'https' : 'http'}://#{Forgery(:internet).domain_name}" }

  #   context 'when given session' do
  #     let(:session) { build(:session, description: "#{Forgery(:lorem_ipsum).words(5, random: true)} #{url}\n#{url2} #{Forgery(:lorem_ipsum).words(5, random: true)}", custom_description_field_value: "#{Forgery(:lorem_ipsum).words(5, random: true)} #{url} #{Forgery(:lorem_ipsum).words(5, random: true)}") }

  #     it 'wraps links in session description' do
  #       session.validate
  #       expect(session.description).to match(/<a href="#{url}".*>#{url}<\/a>/)
  #       expect(session.description).to match(/<a href="#{url2}".*>#{url2}<\/a>/)
  #       expect(session.custom_description_field_value).to match(/<a href="#{url}".*>#{url}<\/a>/)
  #     end
  #   end

  #   context 'when given video' do
  #     let(:video) { build(:video, description: "#{Forgery(:lorem_ipsum).words(5, random: true)} #{url}\n#{url2} #{Forgery(:lorem_ipsum).words(5, random: true)}") }

  #     it 'wraps links in video description' do
  #       video.validate
  #       expect(video.description).to match(/<a href="#{url}".*>#{url}<\/a>/)
  #       expect(video.description).to match(/<a href="#{url2}".*>#{url2}<\/a>/)
  #     end
  #   end

  #   context 'when given recording' do
  #     let(:recording) { build(:recording, description: "#{Forgery(:lorem_ipsum).words(5, random: true)} #{url}\n#{url2} #{Forgery(:lorem_ipsum).words(5, random: true)}") }

  #     it 'wraps links in session description' do
  #       recording.validate
  #       expect(recording.description).to match(/<a href="#{url}".*>#{url}<\/a>/)
  #       expect(recording.description).to match(/<a href="#{url2}".*>#{url2}<\/a>/)
  #     end
  #   end

  #   context 'when given channel' do
  #     let(:channel) { build(:channel, description: "#{Forgery(:lorem_ipsum).words(5, random: true)} #{url}\n#{url2} #{Forgery(:lorem_ipsum).words(5, random: true)}") }

  #     it 'wraps links in channel description' do
  #       channel.validate
  #       expect(channel.description).to match(/<a href="#{url}".*>#{url}<\/a>/)
  #       expect(channel.description).to match(/<a href="#{url2}".*>#{url2}<\/a>/)
  #     end
  #   end
  # end
end
