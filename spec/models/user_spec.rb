# frozen_string_literal: true
require 'spec_helper'
require 'sidekiq/testing'

describe User do
  let(:user) { create(:user) }

  describe 'relations' do
    describe '#views_made' do
      let(:user) { create(:user_view).user }

      it { expect { user.views_made }.not_to raise_error }
    end

    describe '#views_made' do
      let(:user) { create(:user_view).viewable }

      it { expect { user.views }.not_to raise_error }
    end
  end

  describe 'scopes' do
    describe '.not_fake' do
      subject(:tested_scope) { described_class.not_fake }

      it { expect { tested_scope }.not_to raise_error }
    end

    describe '.not_deleted' do
      subject(:tested_scope) { described_class.not_deleted }

      it { expect { tested_scope }.not_to raise_error }
    end

    describe '.for_home_page' do
      subject(:tested_scope) { described_class.for_home_page }

      it { expect { tested_scope }.not_to raise_error }
    end

    describe '.with_follows_count' do
      subject(:tested_scope) { described_class.with_follows_count }

      it { expect { tested_scope }.not_to raise_error }
    end

    describe '.regular_users' do
      subject(:tested_scope) { described_class.regular_users }

      it { expect { tested_scope }.not_to raise_error }
    end

    describe '.service_admins' do
      subject(:tested_scope) { described_class.service_admins }

      it { expect { tested_scope }.not_to raise_error }
    end

    describe '.platform_owners' do
      subject(:tested_scope) { described_class.platform_owners }

      it { expect { tested_scope }.not_to raise_error }
    end
  end

  describe 'slug validation' do
    let(:organization) { create(:organization, name: 'Unique Slug', slug: 'unique-slug') }
    let(:user) { create(:user, first_name: 'Unique', last_name: 'Slug') }

    it { expect(organization.slug).to eq('unique-slug') }
    it { expect(user.slug).not_to eq(organization.slug) }
  end

  describe 'password validation' do
    let(:errors) { user.errors.full_messages.join(',') }

    context 'when creating new user' do
      before do
        user.validate
      end

      let(:user) { build(:user, password: password, password_confirmation: password) }

      context 'when given valid password' do
        let(:password) { 'Az9!@#$' }

        it { expect(user.valid?).to be_truthy }
      end

      context 'when given short password' do
        let(:password) { 'Az9!' }

        it { expect(errors).to include('Password is too short') }
      end

      context 'when given long password' do
        let(:password) { 'Az9!' * 100 }

        it { expect(errors).to include('Password is too long') }
      end

      context 'when given password without lowercase letters' do
        let(:password) { 'AZ9!@#$@#$' }

        it { expect(errors).to include('must contain at least one lowercase letter') }
      end

      context 'when given password without uppercase letters' do
        let(:password) { 'az9!@#$@#$' }

        it { expect(errors).to include('must contain at least one uppercase letter') }
      end

      context 'when given password without numeric digits' do
        let(:password) { 'Az!@#$@#$' }

        it { expect(errors).to include('must contain at least one numeric digit') }
      end

      context 'when given password without numeric digits' do
        let(:password) { 'Az66666' }

        it { expect(user.valid?).to be_truthy }
      end
    end

    context 'when updating existing user' do
      before do
        user.password = user.password_confirmation = password
        user.validate
      end

      context 'when given valid password' do
        let(:password) { 'Az9!@#$' }

        it { expect(user.valid?).to be_truthy }
      end

      context 'when given short password' do
        let(:password) { 'Az9!' }

        it { expect(errors).to include('Password is too short') }
      end

      context 'when given long password' do
        let(:password) { 'Az9!' * 100 }

        it { expect(errors).to include('Password is too long') }
      end

      context 'when given password without lowercase letters' do
        let(:password) { 'AZ9!@#$@#$' }

        it { expect(errors).to include('must contain at least one lowercase letter') }
      end

      context 'when given password without uppercase letters' do
        let(:password) { 'az9!@#$@#$' }

        it { expect(errors).to include('must contain at least one uppercase letter') }
      end

      context 'when given password without numeric digits' do
        let(:password) { 'Az!@#$@#$' }

        it { expect(errors).to include('must contain at least one numeric digit') }
      end

      context 'when given password without numeric digits' do
        let(:password) { 'Az66666' }

        it { expect(user.valid?).to be_truthy }
      end
    end
  end

  describe '#channels_without_sessions' do
    let(:user) { create(:presenter).user }
    let(:organization) { create(:organization, user: user) }
    let(:channel1) { create(:listed_channel, organization: organization) }
    let(:channel2) { create(:listed_channel, organization: organization) }

    it { expect(user.channels_without_sessions).to be_blank }

    it 'works' do
      channel1
      expect(user.channels_without_sessions).to eq([channel1])
    end

    it do
      channel1
      create(:immersive_session, channel: channel2, presenter: user.presenter)
      expect(user.channels_without_sessions).to eq([channel1])
    end
  end

  describe '#utm_content_value' do
    subject { described_class.new(email: 'foo@gmail.com').utm_content_value }

    it { is_expected.to eq('fGZvb0BnbWFpbC5jb20=') }
  end

  describe '#current_phone_is_approved?' do
    subject { user.current_phone_is_approved? }

    context 'when given UA phone number' do
      let(:user) do
        user = create(:user_account, phone: '+380683728661').user

        user.authy_records.create(authy_user_id: '26264786', status: 'approved', cellphone: '683728661',
                                  country_code: '380')

        user
      end

      it { is_expected.to be true }
    end

    context 'when given US phone number' do
      let(:user) do
        user = create(:user_account, phone: '+14692377068').user

        user.authy_records.create(authy_user_id: '28588585', status: 'approved', cellphone: '4692377068',
                                  country_code: '1')

        user
      end

      it { is_expected.to be true }
    end
  end

  describe '#free_sessions_without_admin_approval_left_count' do
    let(:left_count) { user.free_sessions_without_admin_approval_left_count }

    context 'when given new user' do
      let(:user) { create(:presenter).user }

      it { expect(left_count).to eq(0) }
    end

    context 'when given user with non-zero limit' do
      let(:user) { create(:user, can_publish_n_free_sessions_without_admin_approval: 3) }
      let(:presenter) { create(:presenter, user: user) }
      let(:organization) { create(:organization, user: presenter.user) }

      let!(:channel) { create(:approved_channel, organization: organization) }

      before do
        create(:completely_free_session, channel: channel, presenter: presenter)
      end

      it { expect(left_count).to eq(2) }
    end
  end

  describe '#on_demand_sessions' do
    let(:user) { create(:participant).user }

    context 'when given user who bought vod access to session' do
      it 'works' do
        session = create(:immersive_session)
        session.recorded_members.create!(participant: user.participant, status: 'confirmed')
        session.room.update({ vod_is_fully_ready: true })

        expect(user.reload.on_demand_sessions.to_a).to eq([session])
      end
    end

    context 'when given presenter whose vod session is fully ready' do
      it 'works' do
        session = create(:immersive_session)
        session.room.update({ vod_is_fully_ready: true })

        expect(session.organizer.on_demand_sessions).to eq([session])
      end
    end

    context 'when given user who bought vod sessions and organized one himself' do
      let(:channel) { create(:approved_channel) }
      let(:user) { channel.organizer }
      let!(:session2) do
        session2 = create(:immersive_session, channel: channel, presenter: user.presenter)
        session2.room.update({ vod_is_fully_ready: true })
        session2
      end

      let!(:session1) do
        session1 = create(:immersive_session)
        session1.recorded_members.create!(participant: user.create_participant, status: 'confirmed')
        session1.room.update({ vod_is_fully_ready: true })
        session1
      end

      it { expect(user.on_demand_sessions.sort).to eq([session1, session2].sort) }
    end
  end

  describe '#was_ever_invited_as_co_presenter?' do
    let(:user) { create(:presenter).user }

    it { expect(user.was_ever_invited_as_co_presenter?).to eq(false) }

    it 'works' do
      session = create(:immersive_session)
      session.session_invited_immersive_co_presenterships.create(presenter: user.presenter)

      expect(user.was_ever_invited_as_co_presenter?).to eq(true)
    end
  end

  describe '#nearest_abstract_session' do
    let(:user) { create(:participant).user }
    let(:session) { create(:published_session) }

    context 'when given session participation' do
      it { expect(user.nearest_abstract_session).to be_blank }

      it 'works' do
        session.immersive_participants << user.participant

        expect(user.nearest_abstract_session).to eq(session)
      end
    end

    context 'when given livestreamer' do
      it { expect(user.nearest_abstract_session).to be_blank }

      it 'works' do
        session.livestreamers.create!(participant: user.participant, free_trial: false)
        expect(user.nearest_abstract_session).to eq(session)
      end
    end
  end

  describe '#destroy' do
    let!(:user) { create(:user) }
    let!(:user2) { create(:user) }
    let!(:user3) { create(:user) }
    let!(:contact) { create(:contact) }

    before do
      Contact.create!(for_user: user, contact_user: user2)
      Contact.create!(for_user: user3, contact_user: user)
      user.create_participant!

      stub_request(:any, /.*localhost:3001*/)
        .to_return(status: 200, body: '', headers: {})
      user.destroy
    end

    it do
      livestream_session = create(:livestream_session)
      Livestreamer.new(session: livestream_session, participant: user.participant).tap do |model|
        model.save(validate: false)
      end
      expect(Livestreamer.count).to eq(1)
    end

    it do
      user.send_message(user2, 'Body', 'Subject')
      expect(Mailboxer::Conversation.count).to eq(1)
    end

    it do
      user.send_message(user2, 'Body', 'Subject')
      expect(Mailboxer::Message.count).to eq(1)
    end

    it { expect(Rate.count).to eq(0) }
    it { expect(Mailboxer::Conversation.count).to eq(0) }
    it { expect(Mailboxer::Message.count).to eq(0) }
    it { expect(Livestreamer.count).to eq(0) }
    it { expect(Contact.all).to eq([contact]) }
    it { expect(user2.reload).to be_present }
    it { expect(user3.reload).to be_present }
    it { expect(Participant.count).to eq(0) }
  end

  describe '#my_referral_users' do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }

    it 'works' do
      expect(user1.my_referral_users).to eq([])
    end

    it do
      create(:referral, master_user: user1, user: user2)
      expect(user1.my_referral_users).to eq([user2])
    end

    it do
      create(:referral, master_user: user1, user: user2)
      expect(user2.my_referral_users).to eq([])
    end
  end

  describe '#reviews_with_comment' do
    let(:session) { create(:immersive_session) }
    let(:channel) { session.channel }
    let(:user) { create(:participant).user }
    let(:user2) { create(:participant).user }

    it 'works' do
      create(:session_review_with_mandatory_rates, commentable: session)
      create(:session_review_with_mandatory_rates, commentable: create(:immersive_session, channel: channel))
      create_mandatory_rates user, session
      result = channel.organizer.reload.reviews_with_comment
      expect(result.length).to eq(2)
    end
  end

  describe '#user_followers' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it 'does not fail' do
      user1.follow(user2)

      expect(user2.user_followers).to eq([user1])
    end
  end

  describe '#last_followers_as_json' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it 'does not fail' do
      user1.follow(user2)
      actual = JSON.parse user2.last_followers_as_json
      expect(actual).to be_kind_of Array
    end

    it do
      user1.follow(user2)
      actual = JSON.parse user2.last_followers_as_json
      expect(actual.last['avatar_url']).to be_present
    end
  end

  # not duplicating ActsAsFollower's specs, just to clarify
  # followable/following difference
  describe '#follow' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it 'works' do
      expect(user1.following?(user2)).to be false
    end

    context 'with follow user' do
      before do
        user1.follow(user2)
      end

      it { expect(user1.following?(user2)).to be true }
      it { expect(user2.following?(user1)).to be false }
    end

    context 'with follow' do
      before do
        user1.follow(user2)
      end

      it do
        follow = Follow.first
        expect(follow.followable).to eq(user2)
      end

      it do
        follow = Follow.first
        expect(follow.follower).to eq(user1)
      end

      it { expect(user2.user_followers).to eq([user1]) }
      it { expect(user1.following_users).to eq([user2]) }
    end
  end

  describe '#set_display_name' do
    context 'when given invited user with reserved keyword in handle name' do
      let(:user) { described_class.new(email: 'admin@some-website.com') }

      before do
        user.skip_validation_for :email, :first_name, :last_name, :gender, :birthdate
        user.set_display_name
        user.set_authentication_token
        user.skip_confirmation!
        # Skip password validation
        def user.password_required?
          false
        end

        user.save!
      end

      it 'does not fail' do
        expect(user.reload.display_name).to eq('admin-some-website')
      end
    end

    context 'when given user with already set display_name is not unique should be allowed' do
      let(:user) { described_class.new(first_name: 'foo', last_name: nil, display_name: 'John') }

      before do
        create(:user, display_name: 'John')

        user.skip_validation_for :email, :first_name, :last_name, :gender, :birthdate
        user.set_display_name
        user.set_authentication_token
        user.skip_confirmation!
        # Skip password validation
        def user.password_required?
          false
        end

        user.save!
      end

      it 'does not touch display_name' do
        display_name = user.reload.display_name
        expect(display_name).to eq('John') # display name is not uniq
      end
    end
  end

  describe '#available_timezones' do
    let(:available_timezones) { described_class.available_timezones.map(&:to_s) }

    it 'does not include :45-minutes like time zones' do
      expect(available_timezones.any? { |timezone_string| timezone_string.include?(':45') }).to be false
    end
  end

  describe '#mark_as_destroyed' do
    let(:facebook) { create(:facebook_identity) }
    let(:user) { create(:user, email: 'example@gmail.com', identities: [facebook]) }

    it 'soft deletes user' do
      expect(user.deleted).to be false
    end

    it do
      user.mark_as_destroyed
      expect(user.deleted).to be true
    end

    it 'clearing data for next registration' do
      user.mark_as_destroyed
      expect(user.email).to be_blank
    end

    it do
      user.mark_as_destroyed
      expect(user.old_email).to eq('example@gmail.com')
    end

    it do
      user.mark_as_destroyed
      expect(user.identities).to be_blank
    end
  end

  describe '#presenting_at_sessions' do
    subject { current_user.presenting_at_sessions }

    context 'when not presenter at all' do
      let(:current_user) { create(:user) }

      it { is_expected.to eq([]) }
    end

    context 'when organized a session' do
      let(:session) { create(:immersive_session) }
      let(:current_user) { session.organizer }

      it { is_expected.to eq([session]) }
    end
  end

  describe '#co_presenting_or_invited_to_sessions' do
    let(:session_list) { current_user.co_presenting_or_invited_to_sessions }

    let(:session) { create(:published_session) }

    context 'when organized a session' do
      let(:current_user) { session.organizer }

      it { expect(session_list).to eq([]) }
    end

    context 'when co-presenter' do
      let(:current_user) { create(:presenter).user }

      before { session.co_presenters << current_user.presenter }

      it { expect(session_list).to eq([session]) }
    end

    context 'when invited' do
      let(:current_user) { create(:presenter).user }

      it 'when still pending' do
        session.session_invited_immersive_co_presenterships.create(presenter: current_user.presenter,
                                                                   status: ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING)
        expect(session_list).to eq([session])
      end

      it 'when invitation is rejected' do
        session.session_invited_immersive_co_presenterships.create(presenter: current_user.presenter,
                                                                   status: ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED)
        expect(session_list).to eq([])
      end
    end
  end

  describe '#participating_or_invited_to_sessions' do
    let(:sessions_list) { current_user.participating_or_invited_to_sessions }

    context 'when not participant at all' do
      let(:current_user) { create(:user) }

      it { expect(sessions_list).to eq([]) }
    end

    context 'when livestreamer' do
      let(:session) { create(:session_with_livestream_only_delivery) }
      let(:current_user) { create(:participant).user }

      before do
        create(:livestreamer, session: session, participant: current_user.participant)
      end

      it { expect(sessions_list).to eq([session]) }
    end

    context 'when invited as immersive participant' do
      let(:session) { create(:published_session) }
      let(:current_user) { create(:participant).user }

      it 'still pending' do
        session.session_invited_immersive_participantships.create(
          participant: current_user.participant,
          status: ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::PENDING
        )
        expect(sessions_list).to eq([session])
      end

      it 'still approved' do
        session.session_invited_immersive_participantships.create(
          participant: current_user.participant,
          status: ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED
        )
        expect(sessions_list).to eq([session])
      end

      it 'invitation is rejected' do
        session.session_invited_immersive_participantships.create(
          participant: current_user.participant,
          status: ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::REJECTED
        )
        expect(sessions_list).to eq([])
      end
    end

    context 'when invited as livestreamer' do
      let(:session) { create(:published_session) }
      let(:current_user) { create(:participant).user }

      before do
        session.session_invited_livestream_participantships.create!(participant: current_user.participant)
      end

      it { expect(sessions_list).to eq([session]) }
    end

    context 'when user bought immersive participant access' do
      let(:session) { create(:published_session) }
      let(:current_user) { create(:participant).user }

      before { session.immersive_participants << current_user.participant }

      it { expect(sessions_list).to eq([session]) }
    end
  end

  describe '#reminder_notifications' do
    let(:unread_notification) do
      create(:unread_notification, notified_object: user, created_at: 12.hours.from_now,
                                   expires: 1.day.from_now)
    end

    it do
      Timecop.freeze 11.hours.from_now do
        expect(user.reminder_notifications).to be_blank
      end
    end

    it do
      unread_notification
      Timecop.freeze 12.hours.from_now do
        expect(user.reminder_notifications.count).to eq(1)
      end
    end
  end

  describe '#mark_reminder_notifications_as_read' do
    let(:notification) do
      create(:unread_notification, notified_object: user, created_at: 12.hours.ago,
                                   expires: 1.day.from_now)
    end

    it do
      notification
      expect(Mailboxer::Receipt.count).to eq(1)
    end

    it do
      notification
      expect(Mailboxer::Receipt.first.is_read).to be false
    end

    it 'mark as read' do
      user.mark_reminder_notifications_as_read([notification.id])
      expect(Mailboxer::Receipt.first.is_read).to be true
    end
  end

  context 'when slug changes' do
    let(:video) { create(:video) }
    let(:channel) { video.channel }
    let(:user) { channel.organizer }
    let(:recording) { create(:recording, channel: channel) }

    before do
      stub_request(:any, /.*webrtcservice.com*/)
        .to_return(status: 200, body: '', headers: {})
    end

    it 'updates slugs for all nested entities' do
      expect do
        Sidekiq::Testing.inline! do
          user.display_name = 'New Name'
          user.save
        end
        channel.reload
      end.to(change(user, :slug).and(change(channel, :slug)))
    end

    context 'when updates shortened urls for all nested entities' do
      before do
        Sidekiq::Testing.inline! do
          user.display_name = 'New Name'
          user.save
          @channel_shortened_url = Shortener::ShortenedUrl.find_by(url: channel.reload.absolute_path)
        end
      end

      it do
        channel_shortened_url = Shortener::ShortenedUrl.find_by(url: channel.reload.absolute_path)
        expect(channel_shortened_url).not_to be_nil
      end

      it do
        channel_shortened_url = Shortener::ShortenedUrl.find_by(url: channel.reload.absolute_path)
        expect(channel.short_url).to include(channel_shortened_url.unique_key)
      end

      it do
        video_shortened_url = Shortener::ShortenedUrl.find_by(url: video.reload.absolute_path)
        expect(video_shortened_url).not_to be_nil
      end

      it do
        video_shortened_url = Shortener::ShortenedUrl.find_by(url: video.reload.absolute_path)
        expect(video.short_url).to include(video_shortened_url.unique_key)
      end
    end
  end

  describe '#ready_for_wa?' do
    let(:user_ready_for_wa) { create(:listed_channel).organizer }
    let(:user_not_ready_for_wa) { create(:approved_channel).organizer }

    context 'when user is ready to get assigned with wa' do
      it 'returns correct value' do
        expect(user_ready_for_wa.ready_for_wa?).to eq(true)
      end
    end

    context 'when user is not ready to get assigned with wa' do
      it 'returns correct value' do
        expect(user_not_ready_for_wa.ready_for_wa?).to eq(false)
      end
    end
  end

  describe 'when user becomes fake' do
    let(:channel) { create(:listed_channel) }
    let(:recording) { create(:recording_published, channel: channel) }
    let(:session) { create(:recorded_session, channel: channel, start_at: 1.day.from_now) }
    let(:channel_invited_presentership) { create(:channel_invited_presentership_accepted, presenter: user.presenter) }
    let(:video) { session.room.videos.first }
    let(:session_invited_presenter) do
      create(:published_livestream_session,
             channel: channel_invited_presentership.channel,
             presenter: channel_invited_presentership.presenter)
    end
    let(:recorded_session_invited_presenter) do
      create(:recorded_session,
             channel: channel_invited_presentership.channel,
             presenter: channel_invited_presentership.presenter)
    end
    let(:video_invited_presenter) { recorded_session_invited_presenter.records.first }
    let(:user) { channel.organizer }

    context 'with index models' do
      it { expect(video.available_for_search?).to be_truthy }
      it { expect(channel.available_for_search?).to be_truthy }
      it { expect(recording.available_for_search?).to be_truthy }
      it { expect(video_invited_presenter.available_for_search?).to be_truthy }
      it { expect(session_invited_presenter.available_for_search?).to be_truthy }
    end

    context 'without index models' do
      before do
        Sidekiq::Testing.inline! do
          user.update(fake: true)
        end
      end

      it { expect(video.pg_search_document).to be_nil }
      # it{expect(channel.pg_search_document).to be_nil} @Igor this test is failed
      it { expect(recording.pg_search_document).to be_nil }
      it { expect(video_invited_presenter.pg_search_document).to be_nil }
      it { expect(session_invited_presenter.pg_search_document).to be_nil }
    end
  end

  describe '#current_role' do
    context 'when given organization owner' do
      let(:user) { create(:organization).user }

      it { expect { user.current_role }.not_to raise_error }
    end

    context 'when given active organization member' do
      let(:user) { create(:organization_membership).user }

      it { expect { user.current_role }.not_to raise_error }
    end

    context 'when given pending organization member' do
      let(:user) { create(:organization_membership_pending).user }

      it { expect { user.current_role }.not_to raise_error }
    end

    context 'when given organization guest' do
      let(:user) { create(:organization_membership_guest).user }

      it { expect { user.current_role }.not_to raise_error }
    end

    context 'when given user without current organization' do
      it { expect { user.current_role }.not_to raise_error }
    end
  end

  describe '#current_organization_owner?' do
    context 'when given organization owner' do
      let(:user) { create(:organization).user }

      it { expect { user.current_organization_owner? }.not_to raise_error }

      it { expect(user.current_organization_owner?).to be_truthy }
    end

    context 'when given active organization member' do
      let(:user) { create(:organization_membership).user }

      it { expect { user.current_organization_owner? }.not_to raise_error }

      it { expect(user.current_organization_owner?).to be_falsey }
    end

    context 'when given pending organization member' do
      let(:user) { create(:organization_membership_pending).user }

      it { expect { user.current_organization_owner? }.not_to raise_error }

      it { expect(user.current_organization_owner?).to be_falsey }
    end

    context 'when given organization guest' do
      let(:user) { create(:organization_membership_guest).user }

      it { expect { user.current_organization_owner? }.not_to raise_error }

      it { expect(user.current_organization_owner?).to be_falsey }
    end

    context 'when given user without current organization' do
      it { expect { user.current_organization_owner? }.not_to raise_error }

      it { expect(user.current_organization_owner?).to be_falsey }
    end
  end

  describe '#unique_view_group_start_at' do
    let(:user) { build(:user) }

    it { expect { user.unique_view_group_start_at }.not_to raise_error }
  end
end
