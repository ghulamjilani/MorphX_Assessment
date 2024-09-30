# frozen_string_literal: true

require 'spec_helper'

describe SessionCreation do
  let(:organization) { create(:organization) }
  let(:channel) { create(:approved_channel, organization: organization) }
  let(:presenter) { organization.user.presenter }

  let(:min_number_of_immersive_and_livestream_participants) { 2 }
  let(:slots_for_co_presenters_count) { 3 }
  let(:slots_for_invited_participants_count) { 1 }

  let(:invited_users_attributes) do
    invited_users = []
    slots_for_invited_participants_count.times do
      invited_users << create(:participant)
    end
    slots_for_co_presenters_count.times do
      invited_users << create(:presenter)
    end
    invited_users.collect do |model|
      if model.is_a?(Participant)
        { email: model.email, state: ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE }
      else
        { email: model.email, state: ModelConcerns::Session::HasInvitedUsers::States::CO_PRESENTER, organizer_pays: true }
      end
    end
  end

  before do
    stub_request(:any, /.*webrtcservice.com.*/)
      .to_return(status: 200, body: '', headers: {})
  end

  context 'when given non-recurring parameters' do
    let(:session) do
      build(:immersive_session,
            status: nil,
            channel: channel,
            min_number_of_immersive_and_livestream_participants: min_number_of_immersive_and_livestream_participants,
            max_number_of_immersive_participants: min_number_of_immersive_and_livestream_participants + 1)
    end

    it 'saves session' do
      described_class.new(session: session, clicked_button_type: SessionFormButtonTypes::SAVE_AS_DRAFT,
                          ability: NullObject.new, invited_users_attributes: invited_users_attributes, list_ids: []).execute
      expect(Session.count).to eq(1)
    end

    it 'saves start now session' do
      session.start_now = true
      described_class.new(session: session, clicked_button_type: SessionFormButtonTypes::SAVE_AS_DRAFT,
                          ability: NullObject.new, invited_users_attributes: invited_users_attributes, list_ids: []).execute
      expect(Session.count).to eq(1)
    end

    it 'creates waiting_list' do
      described_class.new(session: session, clicked_button_type: SessionFormButtonTypes::SAVE_AS_DRAFT,
                          ability: NullObject.new, invited_users_attributes: invited_users_attributes, list_ids: []).execute
      session = Session.last
      expect(session.session_waiting_list).to be_present
    end

    it { expect(OrganizerAbstractSessionPayPromise.count).to eq(0) }

    it 'saves organizer pay promises' do
      described_class.new(session: session, clicked_button_type: SessionFormButtonTypes::SAVE_AS_DRAFT,
                          ability: NullObject.new, invited_users_attributes: invited_users_attributes, list_ids: []).execute
      expect(OrganizerAbstractSessionPayPromise.count).to eq(slots_for_co_presenters_count)
    end

    it 'saves invited participants' do
      Sidekiq::Testing.inline! do
        described_class.new(session: session, clicked_button_type: SessionFormButtonTypes::SAVE_AS_DRAFT,
                            ability: NullObject.new, invited_users_attributes: invited_users_attributes, list_ids: []).execute
      end
      expect(session.reload.session_invited_immersive_participantships.count).to eq(slots_for_invited_participants_count)
    end

    it { expect(ActionMailer::Base.deliveries.count).to be_zero }

    it 'notifies invited co-presenters and does not send notifications to participants because session is not published yet' do
      expect(described_class.new(session: session, clicked_button_type: SessionFormButtonTypes::SAVE_AS_DRAFT,
                                 ability: NullObject.new, invited_users_attributes: invited_users_attributes, list_ids: []).execute).to be true
    end

    xit do
      described_class.new(session: session, clicked_button_type: SessionFormButtonTypes::SAVE_AS_DRAFT,
                          ability: NullObject.new, invited_users_attributes: invited_users_attributes, list_ids: []).execute
      expect(Session.last).not_to be_published
    end

    it 'creates twitter widget' do
      session.twitter_feed_title = 'rubyonrails'
      allow(CreateTwitterWidget).to receive(:perform)
      expect(described_class.new(session: session, clicked_button_type: SessionFormButtonTypes::SAVE_AS_DRAFT,
                                 ability: NullObject.new, invited_users_attributes: invited_users_attributes, list_ids: []).execute).to be true
    end

    context 'when given recurring parameters' do
      let(:until_date) { (Time.zone.today + 7.days) }
      let(:days) do
        ((Time.zone.today + 1.day)..until_date).map.with_index do |date, i|
          Date::DAYNAMES[date.wday].downcase if i.even?
        end.compact
      end
      let(:session) do
        recurring_settings = ActiveSupport::HashWithIndifferentAccess.new({ 'active' => 'on', 'days' => days,
                                                                            'until' => 'date', 'date' => until_date.strftime('%m/%d/%Y') })
        Date::DAYNAMES[Time.zone.today.wday].downcase

        build(:immersive_session,
              status: nil,
              channel: channel,
              recurring_settings: recurring_settings,
              min_number_of_immersive_and_livestream_participants: min_number_of_immersive_and_livestream_participants,
              max_number_of_immersive_participants: min_number_of_immersive_and_livestream_participants + 1)
      end

      it { expect(Session.count).to eq 0 }

      it 'saves session' do
        described_class.new(session: session, clicked_button_type: 'published', ability: NullObject.new,
                            invited_users_attributes: invited_users_attributes, list_ids: []).execute
        expect([4, 5].freeze).to include Session.count
      end
    end
  end
end
