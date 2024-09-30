# frozen_string_literal: true

require 'spec_helper'
require 'cancan/matchers'
describe AbilityLib::Legacy::CredentialsAbility do
  let(:subject) { described_class.new(current_user) }
  let(:role) { create(:access_management_group) }

  describe '#access(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :access, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        create(:organization_membership, organization: organization, user: current_user)
      end

      it { is_expected.to be_able_to :access, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :access, organization }
    end

    context 'when given service_admin user' do
      let(:current_user) { create(:user_service_admin) }
      let(:organization) { create(:organization) }

      it { is_expected.to be_able_to :access, organization }
    end
  end

  describe '#edit(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :edit, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_organization), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :edit, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :edit, organization }
    end
  end

  describe '#create_channel(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :create_channel, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :create_channel), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :create_channel, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :create_channel, organization }
    end
  end

  describe '#edit_channels(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :edit_channels, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :edit_channel), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :edit_channels, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :edit_channels, organization }
    end
  end

  describe '#submit_for_review(channel)' do
    context 'when approved' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:channel, organization: organization, status: :approved) }

      it { is_expected.not_to be_able_to :submit_for_review, channel }
    end

    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:channel, organization: organization) }

      it { is_expected.to be_able_to :submit_for_review, channel }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:channel) { create(:channel, organization: organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :edit_channel), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :submit_for_review, channel }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:channel) { create(:channel, organization: organization) }

      it { is_expected.not_to be_able_to :submit_for_review, channel }
    end
  end

  describe '#list(channel)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }

      it { is_expected.to be_able_to :list, channel }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :edit_channel), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :list, channel }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }

      it { is_expected.not_to be_able_to :list, channel }
    end
  end

  describe '#archive_channels(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :archive_channels, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :archive_channel), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :archive_channels, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :archive_channels, organization }
    end
  end

  describe '#create_session(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :create_session, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :create_session), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :create_session, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :create_session, organization }
    end
  end

  describe '#edit(session)' do
    context 'when owner' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      it { is_expected.to be_able_to :edit, session }
    end

    context 'when member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :edit_session), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :edit, session }
    end

    context 'when not member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel) }

      it { is_expected.not_to be_able_to :edit, session }
    end
  end

  describe '#cancel(session)' do
    context 'when session has not started yet' do
      context 'when owner' do
        let(:current_user) { create(:presenter).user }
        let(:organization) { create(:organization, user: current_user) }
        let(:channel) { create(:approved_channel, organization: organization) }
        let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

        it { is_expected.to be_able_to :cancel, session }
      end

      context 'when member' do
        let(:current_user) { create(:presenter).user }
        let(:organization) { create(:organization) }
        let(:channel) { create(:approved_channel, organization: organization) }
        let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

        before do
          member = create(:organization_membership, organization: organization, user: current_user)
          create(:access_management_groups_credential,
                 credential: create(:access_management_credential, code: :cancel_session), group: role)
          create(:access_management_groups_member, organization_membership: member, group: role)
        end

        it { is_expected.to be_able_to :cancel, session }
      end

      context 'when not member' do
        let(:current_user) { create(:presenter).user }
        let(:organization) { create(:organization) }
        let(:channel) { create(:approved_channel, organization: organization) }
        let(:session) { create(:immersive_session, channel: channel) }

        it { is_expected.not_to be_able_to :cancel, session }
      end
    end

    context 'when session has started already' do
      context 'when owner' do
        let(:current_user) { create(:presenter).user }
        let(:organization) { create(:organization, user: current_user) }
        let(:channel) { create(:listed_channel, organization: organization) }
        let(:session) do
          session = create(:immersive_session, channel: channel, presenter: current_user.presenter)
          def session.started?
            true
          end
        end

        it { is_expected.not_to be_able_to :cancel, session }
      end
    end
  end

  describe '#clone(session)' do
    context 'when owner' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      it { is_expected.to be_able_to :clone, session }
    end

    context 'when member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :clone_session), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :clone, session }
    end

    context 'when not member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel) }

      it { is_expected.not_to be_able_to :clone, session }
    end
  end

  describe '#invite_to_session(session)' do
    context 'when owner' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      it { is_expected.to be_able_to :invite_to_session, session }
    end

    context 'when member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :invite_to_session), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :invite_to_session, session }
    end

    context 'when not member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel) }

      it { is_expected.not_to be_able_to :invite_to_session, session }
    end
  end

  describe '#start(session)' do
    context 'when owner' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      it { is_expected.to be_able_to :start, session }
    end

    context 'when member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :start_session), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :start, session }
    end

    context 'when not member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel) }

      it { is_expected.not_to be_able_to :start, session }
    end
  end

  describe '#end(session)' do
    context 'when owner' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      it { is_expected.to be_able_to :end, session }
    end

    context 'when member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :end_session), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :end, session }
    end

    context 'when not member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel) }

      it { is_expected.not_to be_able_to :end, session }
    end
  end

  describe '#add_products(session)' do
    context 'when owner' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization, user: current_user) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      it { is_expected.to be_able_to :add_products, session }
    end

    context 'when member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel, presenter: current_user.presenter) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :add_products_to_session), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :add_products, session }
    end

    context 'when not member' do
      let(:current_user) { create(:presenter).user }
      let(:organization) { create(:organization) }
      let(:channel) { create(:approved_channel, organization: organization) }
      let(:session) { create(:immersive_session, channel: channel) }

      it { is_expected.not_to be_able_to :add_products, session }
    end
  end

  describe '#upload_recording(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :upload_recording, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :create_recording), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :upload_recording, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :upload_recording, organization }
    end
  end

  describe '#edit_recording(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :edit_recording, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :edit_recording), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :edit_recording, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :edit_recording, organization }
    end
  end

  describe '#transcode_recording(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :transcode_recording, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :transcode_recording), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :transcode_recording, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :transcode_recording, organization }
    end
  end

  describe '#delete_recording(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :delete_recording, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :delete_recording), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :delete_recording, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :delete_recording, organization }
    end
  end

  describe '#edit_replay(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :edit_replay, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :edit_replay), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :edit_replay, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :edit_replay, organization }
    end
  end

  describe '#transcode_replay(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :transcode_replay, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :transcode_replay), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :transcode_replay, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :transcode_replay, organization }
    end
  end

  describe '#delete_replay(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :delete_replay, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :delete_replay), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :delete_replay, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :delete_replay, organization }
    end
  end

  describe '#manage_product(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :manage_product, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_product), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :manage_product, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :manage_product, organization }
    end
  end

  describe '#manage_roles(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :manage_roles, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_roles), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :manage_roles, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :manage_roles, organization }
    end
  end

  describe '#manage_admin(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :manage_admin, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_admin), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :manage_admin, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :manage_admin, organization }
    end
  end

  describe '#manage_creator(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :manage_creator, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_creator), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :manage_creator, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :manage_creator, organization }
    end
  end

  describe '#manage_enterprise_member(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :manage_enterprise_member, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_enterprise_member), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :manage_enterprise_member, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :manage_enterprise_member, organization }
    end
  end

  describe '#manage_superadmin(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :manage_superadmin, organization }
    end
  end

  describe '#manage_channel_subscription(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :manage_channel_subscription, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_channel_subscription), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :manage_channel_subscription, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :manage_channel_subscription, organization }
    end
  end

  describe '#manage_business_plan(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :manage_business_plan, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_business_plan), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :manage_business_plan, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :manage_business_plan, organization }
    end
  end

  describe '#refund(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :refund, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential, credential: create(:access_management_credential, code: :refund),
                                                     group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :refund, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :refund, organization }
    end
  end

  describe '#manage_payment_method(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :manage_payment_method, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_payment_method), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :manage_payment_method, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :manage_payment_method, organization }
    end
  end

  describe '#view_user_report(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :view_user_report, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :view_user_report), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :view_user_report, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :view_user_report, organization }
    end
  end

  describe '#view_video_report(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :view_video_report, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :view_video_report), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :view_video_report, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :view_video_report, organization }
    end
  end

  describe '#view_billing_report(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :view_billing_report, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :view_billing_report), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :view_billing_report, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :view_billing_report, organization }
    end
  end

  describe '#view_revenue_report(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :view_revenue_report, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :view_revenue_report), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :view_revenue_report, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :view_revenue_report, organization }
    end
  end

  describe '#view_content(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :view_content, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :view_content), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :view_content, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :view_content, organization }
    end
  end

  describe '#manage_blog_post(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :manage_blog_post, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_blog_post), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :manage_blog_post, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :manage_blog_post, organization }
    end
  end

  describe '#moderate_blog_post(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.to be_able_to :moderate_blog_post, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      before do
        member = create(:organization_membership, organization: organization, user: current_user)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :moderate_blog_post), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :moderate_blog_post, organization }
    end

    context 'when not member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }

      it { is_expected.not_to be_able_to :moderate_blog_post, organization }
    end
  end

  describe '#add_role(AccessManagement::Group, Organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }
      let(:role1) { create(:access_management_group) }

      it { is_expected.to be_able_to :add_role, role1, organization }
    end

    context 'when add admin and member is admin' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:member) { create(:organization_membership, organization: organization, user: current_user) }
      let(:role1) { create(:access_management_group) }

      before do
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_admin, type: create(:access_management_type, name: 'Admin')), group: role1)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_admin), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :add_role, role1, organization }
    end

    context 'when add admin and member is not admin' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:member) { create(:organization_membership, organization: organization, user: current_user) }
      let(:role1) { create(:access_management_group) }

      before do
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_admin, type: create(:access_management_type, name: 'Admin')), group: role1)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_creator), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.not_to be_able_to :add_role, role1, organization }
    end

    context 'when add creator and member is creator' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:member) { create(:organization_membership, organization: organization, user: current_user) }
      let(:role1) { create(:access_management_group) }

      before do
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, type: create(:access_management_type, name: 'Creator')), group: role1)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_creator), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :add_role, role1, organization }
    end

    context 'when add member and user is admin' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:member) { create(:organization_membership, organization: organization, user: current_user) }
      let(:role1) { create(:access_management_group) }

      before do
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, type: create(:access_management_type, name: 'Member')), group: role1)
        create(:access_management_groups_credential,
               credential: create(:access_management_credential, code: :manage_enterprise_member), group: role)
        create(:access_management_groups_member, organization_membership: member, group: role)
      end

      it { is_expected.to be_able_to :add_role, role1, organization }
    end
  end

  describe '#edit_roles(organization)' do
    context 'when owner' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization, user: current_user) }

      it { is_expected.not_to be_able_to :edit_roles, current_user, organization }
    end

    context 'when member' do
      let(:current_user) { create(:user) }
      let(:organization) { create(:organization) }
      let(:member) { create(:organization_membership, organization: organization, user: current_user) }

      it { is_expected.not_to be_able_to :edit_roles, current_user, organization }
    end
  end

  describe '#destroy_invitation(SessionInvitedImmersiveParticipantship)' do
    context 'when invitations has status pending' do
      let(:participantship) { create(:session_invited_immersive_participantship) }

      context 'when user is session presenter' do
        let(:current_user) { participantship.session.presenter.user }

        it { is_expected.to be_able_to :destroy_invitation, participantship }
      end

      context 'when user is not session presenter' do
        let(:current_user) { create(:user) }

        it { is_expected.not_to be_able_to :destroy_invitation, participantship }
      end
    end

    context 'when invitations has status accepted' do
      let(:participantship) { create(:accepted_session_invited_immersive_participantship) }
      let(:current_user) { participantship.session.presenter.user }

      it { is_expected.not_to be_able_to :destroy_invitation, participantship }
    end
  end

  describe '#read(OrganizationMembership)' do
    context 'when status active' do
      let(:organization_membership) { create(:organization_membership_active) }
      let(:current_user) { create(:user) }

      it { is_expected.to be_able_to :read, organization_membership }
    end

    context 'when status pending' do
      let(:organization_membership) { create(:organization_membership_pending) }

      context 'when given random user' do
        let(:current_user) { create(:user) }

        it { is_expected.not_to be_able_to :read, organization_membership }
      end

      context 'when given invited user' do
        let(:current_user) { organization_membership.user }

        it { is_expected.to be_able_to :read, organization_membership }
      end

      context 'when given organization owner' do
        let(:current_user) { organization_membership.organization.user }

        it { is_expected.to be_able_to :read, organization_membership }
      end

      context 'when given organization member with necessary credentials' do
        let(:groups_credential) do
          create(:access_management_groups_credential, credential: create(:access_management_credential, code: :manage_admin),
                                                       group: role)
        end
        let(:access_management_groups_member) do
          create(:access_management_groups_member, group: groups_credential.group)
        end
        let(:membership_with_access) { access_management_groups_member.organization_membership }
        let(:organization) { membership_with_access.organization }
        let(:organization_membership) { create(:organization_membership_pending, organization: organization) }
        let(:current_user) { membership_with_access.user }

        it { is_expected.to be_able_to :read, organization_membership }
      end
    end
  end
end
