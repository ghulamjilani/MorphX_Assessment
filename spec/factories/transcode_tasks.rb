# frozen_string_literal: true
FactoryBot.define do
  factory :transcode_task do
    job_id { SecureRandom.hex(16) }
    transcodable { create(%i[video_published recording_published].sample) }
    params { {}.to_json }
    error { 0 }
    percent { 100 }
    status { :completed }
  end

  factory :transcode_task_encoding, parent: :transcode_task do
    percent { rand(99) }
    status { :encoding }
  end

  factory :transcode_task_error, parent: :transcode_task do
    percent { 0 }
    error { 1 }
    error_description { 'Video join v2 error' }
  end

  factory :aa_stub_transcode_tasks, parent: :transcode_task
end
