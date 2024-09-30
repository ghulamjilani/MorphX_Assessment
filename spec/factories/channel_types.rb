# frozen_string_literal: true
FactoryBot.define do
  factory :channel_type do
    description { [ChannelType::Descriptions::SOCIAL, ChannelType::Descriptions::PERFORMANCE].sample }
  end

  factory :performance_channel_type, class: 'ChannelType' do
    description { ChannelType::Descriptions::PERFORMANCE }
  end

  factory :instructional_channel_type, class: 'ChannelType' do
    description { ChannelType::Descriptions::INSTRUCTIONAL }
  end

  factory :social_channel_type, class: 'ChannelType' do
    description { ChannelType::Descriptions::SOCIAL }
  end

  factory :not_selected_channel_type, class: 'ChannelType' do
    description { ChannelType::Descriptions::NOT_SELECTED }
  end

  factory :aa_stub_channel_types, parent: :channel_type
end
