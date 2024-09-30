# frozen_string_literal: true
FactoryBot.define do
  factory :organization_logo do
    organization
    original do
      if Rails.env.test?
        File.open(ImageSample.for_size('100x100'))
      else
        File.open(Dir[File.expand_path Rails.root.join('db/seeds/fixtures/organization_logos/*')].sample)
      end
    end
  end

  factory :aa_stub_organization_logos, parent: :organization_logo
end
