# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe ViewableJobs::IncrementAccumulatedViewsCountJob do
  let(:video) { create(:video) }
  let(:session1) { video.room.session }
  let(:channel) { session1.channel }
  let(:session2) { create(:session, channel: channel) }
  let(:recording) { create(:recording, channel: channel) }
  let(:organization) { channel.organization }
  let(:user) { organization.user }
  let(:visitor1) { create(:user) }
  let(:visitor2) { create(:user) }

  before do
    [video, session1, session2, recording].each do |viewable|
      create(:view, viewable: viewable, user_id: visitor1.id)
      create(:view, viewable: viewable, user_id: visitor1.id)
      create(:view, viewable: viewable, user_id: visitor2.id)
    end
  end

  it 'does not fail and increments views_counts' do
    expect do
      described_class.new.perform
      [video, recording, session1, channel, organization, user].each(&:reload)
    end.to change(video, :views_count).by(3).and change(video, :unique_views_count).by(2).and change(session1, :views_count).by(3).and change(session1, :unique_views_count).by(2).and change(recording, :views_count).by(3).and change(recording, :unique_views_count).by(2).and change(channel, :views_count).by(12).and change(channel, :unique_views_count).by(8).and change(organization, :views_count).by(12).and change(organization, :unique_views_count).by(8).and change(user, :views_count).by(12).and change(user, :unique_views_count).by(8).and change(SearchableJobs::UpdatePgSearchDocumentJob.jobs, :size)
  end
end
