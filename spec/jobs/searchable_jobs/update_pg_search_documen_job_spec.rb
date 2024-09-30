# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

describe SearchableJobs::UpdatePgSearchDocumentJob do
  let(:recording) { create(:recording_published, views_count: (10..20).to_a.sample) }

  it { expect { Sidekiq::Testing.inline! { described_class.perform_async('Recording', recording.id) } }.not_to raise_error }

  it 'updates pg_search_document' do
    Sidekiq::Testing.inline! { described_class.perform_async('Recording', recording.id) }
    expect(recording.pg_search_document.views_count).to eq(recording.views_count)
  end

  it { expect { recording.increment!(:views_count, touch: true) }.to change(described_class.jobs, :size) }
end
