# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::Organization::HasChannels do
  describe '#channels_count' do
    let(:listed_channel) { create(:listed_channel) }
    let(:organization) { listed_channel.organization }
    let(:rejected_channel) { create(:rejected_channel, organization: listed_channel.organization) }
    let(:archived_channel) { create(:archived_channel, organization: rejected_channel.organization) }
    let(:listed_channel2) { create(:listed_channel, organization: archived_channel.organization) }

    context 'when organization has one channel' do
      it { expect { organization.channels_count }.not_to raise_error }

      it { expect(organization.channels_count).to eq(1) }
    end

    context 'when organization has more than one channel channel' do
      let(:organization) { listed_channel2.organization }

      before do
        organization
      end

      it { expect { organization.channels_count }.not_to raise_error }

      it { expect(organization.channels_count).to eq(2) }
    end
  end

  describe '#default_user_channel' do
    let(:default_channel) { create(:listed_channel, is_default: true, organization: secondary_channel.organization) }
    let(:secondary_channel) { create(:listed_channel, is_default: false) }

    context 'when organization has no default channel' do
      let(:user) { create(:user) }
      let(:organization) { secondary_channel.organization }

      it { expect { organization.default_user_channel(user) }.not_to raise_error }

      it { expect(organization.default_user_channel(user)).to eq(secondary_channel) }
    end

    context 'when organization has two channels including default one' do
      let(:user) { create(:user) }
      let(:organization) { default_channel.organization }

      it { expect { organization.default_user_channel(user) }.not_to raise_error }

      it { expect(organization.default_user_channel(user)).to eq(default_channel) }
    end

    context 'when organization has two channels including default one which is archived' do
      let(:user) { create(:user) }
      let(:organization) { default_channel.organization }
      let(:default_channel) { create(:archived_channel, is_default: true, organization: secondary_channel.organization) }

      it { expect { organization.default_user_channel(user) }.not_to raise_error }

      it { expect(organization.default_user_channel(user)).to eq(secondary_channel) }
    end
  end
end
