# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::User::HasChannels do
  describe '#owned_and_invited_channels' do
    subject(:tested_method) { user.owned_and_invited_channels }

    context 'given channel owner' do
      let(:user) { create(:channel).organizer }

      it { expect { tested_method }.not_to raise_error }
    end

    context 'given invited presenter' do
      let(:user) { create(:channel_invited_presentership_accepted).presenter.user }

      it { expect { tested_method }.not_to raise_error }
    end

    context 'given random user' do
      let(:user) { create(:user) }

      it { expect { tested_method }.not_to raise_error }
    end
  end

  describe '#all_channels' do
    subject(:tested_method) { user.all_channels }

    context 'given channel owner' do
      let(:user) { create(:channel).organizer }

      it { expect { tested_method }.not_to raise_error }
    end

    context 'given invited presenter' do
      let(:user) { create(:channel_invited_presentership_accepted).presenter.user }

      it { expect { tested_method }.not_to raise_error }
    end

    context 'given random user' do
      let(:user) { create(:user) }

      it { expect { tested_method }.not_to raise_error }
    end
  end

  describe '#owned_channels' do
    subject(:tested_method) { user.owned_channels }

    context 'given channel owner' do
      let(:user) { create(:channel).organizer }

      it { expect { tested_method }.not_to raise_error }
    end

    context 'given invited presenter' do
      let(:user) { create(:channel_invited_presentership_accepted).presenter.user }

      it { expect { tested_method }.not_to raise_error }
    end

    context 'given random user' do
      let(:user) { create(:user) }

      it { expect { tested_method }.not_to raise_error }
    end
  end

  describe '#invited_channels' do
    subject(:tested_method) { user.invited_channels }

    context 'given channel owner' do
      let(:user) { create(:channel).organizer }

      it { expect { tested_method }.not_to raise_error }
    end

    context 'given invited presenter' do
      let(:user) { create(:channel_invited_presentership_accepted).presenter.user }

      it { expect { tested_method }.not_to raise_error }
    end

    context 'given random user' do
      let(:user) { create(:user) }

      it { expect { tested_method }.not_to raise_error }
    end
  end

  describe '#has_owned_channels?' do
    subject(:tested_method) { user.has_owned_channels? }

    context 'given channel owner' do
      let(:user) { create(:channel).organizer }

      it { expect { tested_method }.not_to raise_error }
      it { expect(tested_method).to be_truthy }
    end

    context 'given invited presenter' do
      let(:user) { create(:channel_invited_presentership_accepted).presenter.user }

      it { expect { tested_method }.not_to raise_error }
      it { expect(tested_method).to be_falsey }
    end

    context 'given random user' do
      let(:user) { create(:user) }

      it { expect { tested_method }.not_to raise_error }
      it { expect(tested_method).to be_falsey }
    end
  end

  describe '#has_approved_channels?' do
    subject(:tested_method) { user.has_approved_channels? }

    context 'given channel owner' do
      let(:user) { channel.organizer }

      context 'given pending channel' do
        let(:channel) { create(:pending_channel) }

        it { expect { tested_method }.not_to raise_error }
        it { expect(tested_method).to be_falsey }
      end

      context 'given approved channel' do
        let(:channel) { create(:approved_channel) }

        it { expect { tested_method }.not_to raise_error }
        it { expect(tested_method).to be_truthy }
      end
    end

    context 'given invited presenter' do
      let(:user) { create(:channel_invited_presentership_accepted).presenter.user }

      it { expect { tested_method }.not_to raise_error }
      it { expect(tested_method).to be_falsey }
    end

    context 'given random user' do
      let(:user) { create(:user) }

      it { expect { tested_method }.not_to raise_error }
      it { expect(tested_method).to be_falsey }
    end
  end

  describe '#has_listed_channels?' do
    subject(:tested_method) { user.has_listed_channels? }

    context 'given channel owner' do
      let(:user) { channel.organizer }

      context 'given pending channel' do
        let(:channel) { create(:pending_channel) }

        it { expect { tested_method }.not_to raise_error }
        it { expect(tested_method).to be_falsey }
      end

      context 'given approved channel' do
        let(:channel) { create(:approved_channel) }

        it { expect { tested_method }.not_to raise_error }
        it { expect(tested_method).to be_falsey }
      end

      context 'given listed channel' do
        let(:channel) { create(:listed_channel) }

        it { expect { tested_method }.not_to raise_error }
        it { expect(tested_method).to be_truthy }
      end
    end

    context 'given random user' do
      let(:user) { create(:user) }

      it { expect { tested_method }.not_to raise_error }
      it { expect(tested_method).to be_falsey }
    end
  end

  describe '#has_invited_channels?' do
    subject(:tested_method) { user.has_invited_channels? }

    context 'given channel owner' do
      let(:user) { create(:channel).organizer }

      it { expect { tested_method }.not_to raise_error }
      it { expect(tested_method).to be_falsey }
    end

    context 'given invited presenter' do
      let(:credential) { create(:access_management_credential, code: :start_session) }
      let(:group) { create(:access_management_groups_credential, credential: credential).group }
      let(:groups_member) { create(:access_management_groups_member, group: group) }
      let(:user) { create(:access_management_groups_members_channel, groups_member: groups_member).user }

      it { expect { tested_method }.not_to raise_error }
      it { expect(tested_method).to be_truthy }
    end

    context 'given random user' do
      let(:user) { create(:user) }

      it { expect { tested_method }.not_to raise_error }
      it { expect(tested_method).to be_falsey }
    end
  end

  describe '#has_any_channel?' do
    subject(:tested_method) { user.has_any_channel? }

    context 'given channel owner' do
      let(:user) { create(:channel).organizer }

      it { expect { tested_method }.not_to raise_error }
      it { expect(tested_method).to be_truthy }
    end

    context 'given invited presenter' do
      let(:user) { create(:channel_invited_presentership_accepted).presenter.user }

      it { expect { tested_method }.not_to raise_error }
      it { expect(tested_method).to be_truthy }
    end

    context 'given random user' do
      let(:user) { create(:user) }

      it { expect { tested_method }.not_to raise_error }
      it { expect(tested_method).to be_falsey }
    end
  end
end
