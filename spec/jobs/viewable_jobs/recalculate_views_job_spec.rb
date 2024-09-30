# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe ViewableJobs::RecalculateViewsJob do
  let(:session) { create(:immersive_session) }
  let(:recording) { create(:recording_published, channel: channel) }
  let(:blog_post) { create(:blog_post_published, channel: channel) }
  let(:session_view) { create(:session_view, viewable: session) }
  let(:recording_view) { create(:recording_view, viewable: recording) }
  let(:blog_post_view) { create(:blog_post_view, viewable: blog_post) }
  let(:video_view) { create(:video_view) }
  let(:video) { video_view.viewable }
  let(:channel) { session.channel }
  let(:organization) { channel.organization }
  let(:user) { organization.user }

  before do
    session_view
    video_view
    recording_view
    blog_post_view
    session.update_columns(views_count: 0, unique_views_count: 0)
    video.update_columns(views_count: 0, unique_views_count: 0)
    recording.update_columns(views_count: 0, unique_views_count: 0)
    blog_post.update_columns(views_count: 0, unique_views_count: 0)
  end

  it 'does not fail and recalculates views counts' do
    expect do
      described_class.new.perform
    end.not_to raise_error

    session.reload
    recording.reload
    video.reload
    channel.reload
    organization.reload
    user.reload
    blog_post.reload

    expect(session.views_count).to eq(1)
    expect(session.unique_views_count).to eq(1)
    expect(video.views_count).to eq(1)
    expect(video.unique_views_count).to eq(1)
    expect(recording.views_count).to eq(1)
    expect(recording.unique_views_count).to eq(1)
    expect(blog_post.views_count).to eq(1)
    expect(blog_post.unique_views_count).to eq(1)

    expect(channel.views_count).to eq(2)
    expect(channel.unique_views_count).to eq(2)
    expect(organization.views_count).to eq(2)
    expect(organization.unique_views_count).to eq(2)
    expect(user.views_count).to eq(2)
    expect(user.unique_views_count).to eq(2)

    expect(video.channel.views_count).to eq(1)
    expect(video.channel.unique_views_count).to eq(1)
    expect(video.channel.organization.views_count).to eq(1)
    expect(video.channel.organization.unique_views_count).to eq(1)
    expect(video.channel.organization.user.views_count).to eq(1)
    expect(video.channel.organization.user.unique_views_count).to eq(1)
  end
end
