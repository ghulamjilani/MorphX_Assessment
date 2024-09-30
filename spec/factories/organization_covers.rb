# frozen_string_literal: true
FactoryBot.define do
  factory :organization_cover do
    organization
    original do
      if Rails.env.test?
        File.open(ImageSample.for_size('600x300'))
      else
        File.open(Dir[File.expand_path Rails.root.join('db/seeds/fixtures/organization_covers/*')].sample)
      end
    end
  end
  factory :aa_stub_organization_covers, parent: :organization_cover
end
