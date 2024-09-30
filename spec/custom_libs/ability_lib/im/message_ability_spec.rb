# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'

describe AbilityLib::Im::MessageAbility do
  let(:subject) { described_class.new(current_user) }
  let(:im_message) { create(:im_message) }
  let(:groups_member) { create(:access_management_groups_member, group: create(:access_management_groups_credential, credential: create(:access_management_credential, code: :moderate_channel_conversation)).group) }
  let(:groups_members_channel) { create(:access_management_groups_members_channel, groups_member: groups_member) }

  describe '#edit, #moderate' do
    context 'when given random user' do
      let(:current_user) { create(:user) }

      it { is_expected.not_to be_able_to :edit, im_message }

      it { is_expected.not_to be_able_to :moderate, im_message }
    end

    context 'when given message author' do
      let(:current_user) { im_message.abstract_user }

      it { is_expected.to be_able_to :edit, im_message }

      it { is_expected.not_to be_able_to :moderate, im_message }
    end

    context 'when given user with moderate channel credential' do
      let(:current_user) { groups_members_channel.user }
      let(:im_message) { create(:im_message, conversation: groups_members_channel.channel.im_conversation) }

      it { is_expected.not_to be_able_to :edit, im_message }

      it { is_expected.to be_able_to :moderate, im_message }
    end
  end
end
