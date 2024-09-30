# frozen_string_literal: true
require 'spec_helper'

describe Channel do
  let(:channel) { create(:channel) }

  describe '.visible_for_user for marketplace' do
    let(:user) { create(:user) }
    let(:listed_channel) { create(:listed_channel) }
    let(:approved_channel) { create(:approved_channel) }
    let(:fake_channel) { create(:channel_fake) }

    context 'when no user given' do
      let(:user) { nil }

      it { expect(described_class.visible_for_user(user).where(id: listed_channel.id)).to exist }

      it { expect(described_class.visible_for_user(user).where(id: approved_channel.id)).not_to exist }

      it { expect(described_class.visible_for_user(user).where(id: fake_channel.id)).not_to exist }
    end

    context 'when given random user' do
      it { expect(described_class.visible_for_user(user).where(id: listed_channel.id)).to exist }

      it { expect(described_class.visible_for_user(user).where(id: approved_channel.id)).not_to exist }

      it { expect(described_class.visible_for_user(user).where(id: fake_channel.id)).not_to exist }
    end

    context 'when given service_admin user' do
      let(:user) { create(:user_service_admin) }

      it { expect(described_class.visible_for_user(user).where(id: listed_channel.id)).to exist }

      it { expect(described_class.visible_for_user(user).where(id: approved_channel.id)).to exist }

      it { expect(described_class.visible_for_user(user).where(id: fake_channel.id)).to exist }
    end

    context 'when given user with channel credentials' do
      let(:access_management_credential) do
        create(:access_management_credential, code: ::AccessManagement::Credential::Codes::EDIT_CHANNEL,
                                              is_for_channel: true)
      end
      let(:group_credential) do
        create(:access_management_organizational_groups_credential, credential: access_management_credential)
      end
      let(:group) { group_credential.group }
      let(:organization) { group.organization }
      let(:group_member) do
        create(:access_management_groups_member, group: group,
                                                 organization_membership: create(:organization_membership, organization: organization))
      end
      let(:user) { group_member.user }

      context 'when group member is not assigned to any channel' do
        context 'when channel is listed' do
          let!(:channel) { create(:listed_channel, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).to exist }
        end

        context 'when channel is not listed' do
          let!(:channel) { create(:approved_channel, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).to exist }
        end

        context 'when channel is fake' do
          let!(:channel) { create(:listed_channel, fake: true, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).to exist }
        end
      end

      context 'when group member assigned to specific channel' do
        let(:group_member_channel) do
          create(:access_management_groups_members_channel, groups_member: group_member, channel: channel)
        end
        let(:user) { group_member_channel.user }

        context 'when channel is listed' do
          let!(:channel) { create(:listed_channel, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).to exist }
        end

        context 'when channel is not listed' do
          let!(:channel) { create(:approved_channel, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).to exist }
        end

        context 'when channel is fake' do
          let!(:channel) { create(:listed_channel, fake: true, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).to exist }
        end
      end
    end
  end

  describe '.visible_for_user for enterprise' do
    let(:global_credentials) do
      global_credentials = JSON.parse(Rails.application.credentials.global.to_json).deep_symbolize_keys
      global_credentials[:enterprise] = true
      global_credentials
    end
    let(:user) { create(:user) }
    let(:listed_channel) { create(:listed_channel) }
    let(:approved_channel) { create(:approved_channel) }
    let(:fake_channel) { create(:channel_fake) }

    before do
      allow(Rails.application.credentials).to receive(:global).and_return(global_credentials)
    end

    context 'when no user given' do
      let(:user) { nil }

      it { expect(described_class.visible_for_user(user).where(id: listed_channel.id)).not_to exist }

      it { expect(described_class.visible_for_user(user).where(id: approved_channel.id)).not_to exist }

      it { expect(described_class.visible_for_user(user).where(id: fake_channel.id)).not_to exist }
    end

    context 'when given random user' do
      it { expect(described_class.visible_for_user(user).where(id: listed_channel.id)).not_to exist }

      it { expect(described_class.visible_for_user(user).where(id: approved_channel.id)).not_to exist }

      it { expect(described_class.visible_for_user(user).where(id: fake_channel.id)).not_to exist }
    end

    context 'when given service_admin user' do
      let(:user) { create(:user_service_admin) }

      it { expect(described_class.visible_for_user(user).where(id: listed_channel.id)).to exist }

      it { expect(described_class.visible_for_user(user).where(id: approved_channel.id)).to exist }

      it { expect(described_class.visible_for_user(user).where(id: fake_channel.id)).to exist }
    end

    context 'when given user with edit channel credentials' do
      let(:access_management_credential) do
        create(:access_management_credential, code: ::AccessManagement::Credential::Codes::EDIT_CHANNEL,
                                              is_for_channel: true)
      end
      let(:group_credential) do
        create(:access_management_organizational_groups_credential, credential: access_management_credential)
      end
      let(:group) { group_credential.group }
      let(:organization) { group.organization }
      let(:group_member) do
        create(:access_management_groups_member, group: group,
                                                 organization_membership: create(:organization_membership, organization: organization))
      end
      let(:user) { group_member.user }

      context 'when group member is not assigned to any channel' do
        context 'when channel is listed' do
          let!(:channel) { create(:listed_channel, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).to exist }
        end

        context 'when channel is not listed' do
          let!(:channel) { create(:approved_channel, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).to exist }
        end

        context 'when channel is fake' do
          let!(:channel) { create(:listed_channel, fake: true, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).to exist }
        end
      end

      context 'when group member assigned to specific channel' do
        let(:group_member_channel) do
          create(:access_management_groups_members_channel, groups_member: group_member, channel: channel)
        end
        let(:user) { group_member_channel.user }

        context 'when channel is listed' do
          let!(:channel) { create(:listed_channel, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).to exist }
        end

        context 'when channel is not listed' do
          let!(:channel) { create(:approved_channel, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).to exist }
        end

        context 'when channel is fake' do
          let!(:channel) { create(:listed_channel, fake: true, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).to exist }
        end
      end
    end

    context 'when given user with view_content credential' do
      let(:access_management_credential) do
        create(:access_management_credential, code: ::AccessManagement::Credential::Codes::VIEW_CONTENT,
                                              is_for_channel: true)
      end
      let(:group_credential) do
        create(:access_management_organizational_groups_credential, credential: access_management_credential)
      end
      let(:group) { group_credential.group }
      let(:organization) { group.organization }
      let(:group_member) do
        create(:access_management_groups_member, group: group,
                                                 organization_membership: create(:organization_membership, organization: organization))
      end
      let(:user) { group_member.user }

      context 'when group member is not assigned to any channel' do
        context 'when channel is listed' do
          let!(:channel) { create(:listed_channel, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).to exist }
        end

        context 'when channel is not listed' do
          let!(:channel) { create(:approved_channel, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).not_to exist }
        end

        context 'when channel is fake' do
          let!(:channel) { create(:listed_channel, fake: true, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).to exist }
        end
      end

      context 'when group member assigned to specific channel' do
        let(:group_member_channel) do
          create(:access_management_groups_members_channel, groups_member: group_member, channel: channel)
        end
        let(:user) { group_member_channel.user }

        context 'when channel is listed' do
          let!(:channel) { create(:listed_channel, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).to exist }
        end

        context 'when channel is not listed' do
          let!(:channel) { create(:approved_channel, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).not_to exist }
        end

        context 'when channel is fake' do
          let!(:channel) { create(:listed_channel, fake: true, organization: organization) }

          it { expect(described_class.visible_for_user(user).where(id: channel.id)).to exist }
        end
      end
    end
  end

  describe '#reviews_with_comment' do
    let(:session) { create(:immersive_session) }
    let(:channel) { session.channel }
    let(:user) { create(:participant).user }
    let(:user2) { create(:participant).user }

    before do
      def session.can_rate?(_user, _dimension = nil)
        true
      end

      session.start_at = Time.zone.now.beginning_of_hour - 1.day - Session.where("now() > (start_at + (INTERVAL '1 minute' * duration))").count.days
      def session.not_in_the_past
        # skip it
      end
      session.save!

      session.immersive_participants << user.participant

      Session::RateKeys::MANDATORY.each do |mandatory_key|
        session.rate((1..5).to_a.sample, user, mandatory_key)
      end

      Review.create!(user: user, title: '', overall_experience_comment: 'looks really good', commentable: session)

      session.rate(2, user2, Session::RateKeys::MANDATORY.first)
    end

    it 'works' do
      result = session.channel.reviews_with_comment
      expect(result.length).to eq(1)
    end
  end

  describe '#subscribers' do
    let(:channel1) { create(:channel) }
    let(:user1) { create(:user) }

    it 'does not fail' do
      user1.follow(channel1)

      expect(channel1.subscribers).to eq([user1])
    end
  end

  describe '#listed_at flush' do
    let(:channel) { create(:listed_channel) }

    %w[draft rejected].each do |status|
      context "when status is set to #{status} from admin interface" do
        it 'works' do
          expect(channel).to be_listed
        end

        it do
          channel.status = status
          channel.rejection_reason = 'just because' if status == 'rejected'
          channel.save!

          expect(channel).not_to be_listed
        end
      end
    end
  end

  context 'when Validations' do
    context 'when uniq title' do
      let(:archived_channel) { create(:channel, title: 'super', archived_at: Time.zone.today - 2) }
      let(:channel) { create(:channel, title: 'super') }

      it { expect(archived_channel.archived?).to be true }
      it { expect(archived_channel.title).to eq('super') }
      it { expect(channel.archived?).to be false }
      it { expect(channel.title).to eq('super') }
    end

    context 'when status rejected' do
      let(:channel) { create(:channel) }

      before { allow(channel).to receive(:rejected?).and_return(true) }

      it { expect(channel).to validate_presence_of(:rejection_reason) }
    end

    context 'with channel location' do
      let(:channel) { create(:channel) }

      it { expect(channel.channel_location.blank?).to eq(false) }
      it { expect(channel.valid?).to eq(true) }

      it 'allows blank channel location' do
        channel.channel_location = ''
        expect(channel.valid?).to eq(true)
      end

      it do
        channel.channel_location = nil
        expect(channel.valid?).to eq(true)
      end
    end

    context 'when status not rejected' do
      let(:channel) { create(:channel) }

      before { allow(channel).to receive(:rejected?).and_return(false) }

      it { expect(channel).not_to validate_presence_of(:rejection_reason) }
    end

    context 'when given channel with way too many images' do
      subject { channel.errors.full_messages }

      let(:channel) do
        build(:channel_with_image).tap do |p|
          p.cover = FactoryBot.build(:main_channel_image, channel: p)
          p.images = []
          (SystemParameter.channel_images_max_count.to_i + 1).times do
            p.images << FactoryBot.build(:channel_image, channel: p, is_main: false)
          end
          p.valid?(:channel_controller)
        end
      end

      it { is_expected.to eq(['Gallery must have at most 15 images']) }
    end
  end

  describe 'callbacks' do
    let(:channel) { create(:channel) }

    context 'when vclear_fields' do
      before do
        channel.update({ rejection_reason: 'bla bla' })
      end

      it 'clears rejection_reason if status eq approved' do
        expect(channel.rejection_reason).to eq 'bla bla'
      end

      it do
        channel.update({ status: 'approved' })
        expect(channel.rejection_reason).to eq nil
      end
    end

    context 'when send_notice' do
      it 'when sents mail once if status rejected' do
        channel.title = 'updated title after rejection'
        channel.save!

        mailer = double
        allow(mailer).to receive(:deliver_later)

        allow(ChannelMailer).to receive(:channel_rejected).once.with(channel.id).and_return(mailer)
      end
    end

    context 'when multisearch index' do
      it 'invokes multisearch indexing after update if title changed' do
        channel.title = 'updated title after rejection'
        expect(channel).to receive(:schedule_update_pg_search_document).at_least(:once)
        channel.save
      end

      it 'invokes multisearch indexing after update if description changed' do
        channel.description = 'updated title after rejection' * 10
        expect(channel).to receive(:schedule_update_pg_search_document).at_least(:once)

        channel.save
      end

      it 'invokes multisearch indexing after update if tags changed' do
        channel.tag_list = 'trol,lol,pfff'
        expect(channel).to receive(:schedule_update_pg_search_document).at_least(:once)
        channel.save
      end

      it 'invokes multisearch indexing after update if slug changed' do
        channel.slug = 'trololo'
        expect(channel).to receive(:schedule_update_pg_search_document).at_least(:once)
        channel.save
      end
    end
  end

  describe '#submit_for_review!' do
    context 'when given draft channel' do
      let(:channel) { create(:channel) }

      before do
        mailer = double
        allow(mailer).to receive(:deliver_later).at_least(:once)

        allow(ChannelMailer).to receive(:pending_channel_appeared).at_least(:once).and_return(mailer)
      end

      it { expect(channel).to be_draft }

      it do
        channel.submit_for_review!
        expect(channel).not_to be_draft
      end

      it 'works' do
        channel.submit_for_review!
        expect(channel).to be_pending_review
      end
    end
  end

  context 'when given submitted channel' do
    let(:channel) { create(:channel, status: Channel::Statuses::PENDING_REVIEW) }

    before do
      if rand(2).zero?
        channel.approve!
      else
        # if called from RailsAdmin
        channel.status = Channel::Statuses::APPROVED
        channel.save!
      end
    end

    it 'notifies organizer when it got approved by admins' do
      expect(ApplicationMailDeliveryJob).to(
        have_been_enqueued.with('ChannelMailer', 'channel_approved', 'deliver_now', args: [channel.id])
      )
    end
  end

  describe '#performance_type?' do
    let(:performance_type) { create(:performance_channel_type) }
    let(:instructional_type) { create(:instructional_channel_type) }

    it 'works' do
      channel = described_class.new(channel_type: performance_type)
      expect(channel).to be_performance_type
    end

    it do
      Rails.cache.clear
      channel = described_class.new(channel_type: instructional_type)
      expect(channel).not_to be_performance_type
    end
  end

  describe '#tag_list when add a nonexistant tag' do
    let(:channel) do
      channel = create(:channel)
      channel.tag_list.add('some_tag')
      channel.save
      channel
    end

    let(:tag) do
      channel
      ActsAsTaggableOn::Tag.find_by(name: 'some_tag')
    end

    it do
      expect(tag.nil?).to be false
    end

    it 'creates the tag and adds it to the channel' do
      expect(channel.reload.tags).to include(tag)
    end
  end

  describe '#tag_list=' do
    describe 'create and add all tags from list' do
      let(:channel) do
        channel = create(:channel)
        channel.tag_list = 'tag1,tag2,tag3'
        channel.save
        channel.reload
      end
      let(:t1) do
        channel
        ActsAsTaggableOn::Tag.find_by(name: 'tag1')
      end
      let(:t2) do
        channel
        ActsAsTaggableOn::Tag.find_by(name: 'tag2')
      end
      let(:t3) do
        channel
        ActsAsTaggableOn::Tag.find_by(name: 'tag3')
      end

      it { expect(t1.nil?).to be false }
      it { expect(t2.nil?).to be false }
      it { expect(t3.nil?).to be false }
      it { expect(channel.tags).to include(t1) }
      it { expect(channel.tags).to include(t2) }
      it { expect(channel.tags).to include(t3) }
    end
  end

  describe '#list_immediately' do
    let(:channel1) { create(:approved_channel) }

    it 'lists the channel' do
      expect { channel1.send(:list_immediately) }.to(change(channel1, :listed_at))
    end
  end

  describe '#is_default' do
    let(:channel) { create(:approved_channel, is_default: true) }

    it 'change default channel' do
      expect { create(:approved_channel, organization: channel.organization, is_default: true) }.to(change do
                                                                                                      channel.reload.is_default
                                                                                                    end)
    end
  end

  describe '#presenters' do
    subject(:presenters) { channel.presenters }

    let(:presentership) { create(:channel_invited_presentership) }
    let(:channel) { presentership.channel }

    it { expect { presenters }.not_to raise_error }

    context 'given accepted channel presentership' do
      let(:presentership) { create(:channel_invited_presentership_accepted) }

      it 'includes presenter' do
        expect(presenters.exists?(id: presentership.presenter_id)).to be_truthy
      end
    end

    context 'given pending channel presentership' do
      let(:presentership) { create(:channel_invited_presentership_pending) }

      it 'does not include presenter' do
        expect(presenters.exists?(id: presentership.presenter_id)).to be_falsey
      end
    end

    context 'given rejected channel presentership' do
      let(:presentership) { create(:channel_invited_presentership_rejected) }

      it 'does not include presenter' do
        expect(presenters.exists?(id: presentership.presenter_id)).to be_falsey
      end
    end
  end

  describe '#live_session_exists?' do
    subject(:live_session_exists) { channel.live_session_exists? }

    let(:channel) { create(:approved_channel) }

    it { expect { live_session_exists }.not_to raise_error }
  end

  describe '#notify_im_conversation_disabled' do
    let(:channel) { create(:approved_channel) }

    it { expect { channel.send(:notify_im_conversation_disabled) }.not_to raise_error }
  end
end
