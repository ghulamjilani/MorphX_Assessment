# frozen_string_literal: true
FactoryBot.define do
  factory :stream_preview do
    organization
    user { organization&.user }
    ffmpegservice_account {create(:ffmpegservice_account, organization: organization, sandbox: true) }
  end

  factory :stream_preview_finished, parent: :stream_preview do
    created_at { 10.minutes.ago }
    updated_at { 10.minutes.ago }
    stopped_at { 6.minutes.ago }
  end

  factory :stream_preview_stopped, parent: :stream_preview do
    created_at { 2.minutes.ago }
    stopped_at { 1.minute.ago }
  end

  factory :stream_preview_passed, parent: :stream_preview do
    created_at { 10.minutes.ago }
    updated_at { 10.minutes.ago }
  end

  factory :aa_stub_stream_previews, parent: :stream_preview
end
