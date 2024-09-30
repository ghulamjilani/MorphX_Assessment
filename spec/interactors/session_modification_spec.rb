# frozen_string_literal: true

require 'spec_helper'

describe SessionModification do
  let(:presenter) { create(:presenter, user: create(:user_with_credit_card)) }
  let(:organization) { create(:organization, user: presenter.user) }
  let(:channel) { create(:approved_channel, organization: organization) }
  let!(:session1) do
    session = build(:immersive_session,
                    channel: channel,
                    immersive_access_cost: 26.1,
                    min_number_of_immersive_and_livestream_participants: 2,
                    max_number_of_immersive_participants: 2)

    expect(SessionCreation.new(session: session,
                               clicked_button_type: SessionFormButtonTypes::SAVE_AS_DRAFT,
                               ability: NullObject.new,
                               # invited_co_presenters_attributes: [],
                               invited_users_attributes: [],
                               list_ids: []).execute).to be true

    session
  end

  let(:set_slots_for_co_presenters_count) { 3 }
  let(:slots_for_invited_participants_count) { 1 }

  # let(:invited_co_presenters_attributes) do
  #  invited_co_presenters = []
  #  set_slots_for_co_presenters_count.times do
  #    invited_co_presenters << create(:presenter)
  #  end
  #  invited_co_presenters.collect do |presenter|
  #    {email: presenter.email}
  #  end
  # end

  let(:invited_users_attributes) do
    invited_users = []
    slots_for_invited_participants_count.times do
      invited_users << create(:participant)
    end

    set_slots_for_co_presenters_count.times do
      invited_users << create(:presenter)
    end

    invited_users.collect do |model|
      if model.is_a?(Participant)
        { email: model.email, state: ModelConcerns::Session::HasInvitedUsers::States::IMMERSIVE }
      else
        { email: model.email, state: ModelConcerns::Session::HasInvitedUsers::States::CO_PRESENTER }
      end
    end
  end

  before do
    session1.session_invited_immersive_participantships

    session1.title = 'fooooo'
    session1.start_now = true
    session1.min_number_of_immersive_and_livestream_participants = 2
    session1.immersive_access_cost = 34.2
    described_class.new(session: session1,
                        clicked_button_type: SessionFormButtonTypes::SAVE_AS_DRAFT,
                        ability: NullObject.new,
                        # invited_co_presenters_attributes: invited_co_presenters_attributes,
                        invited_users_attributes: invited_users_attributes,
                        list_ids: []).execute
  end

  it 'updates basic session attributes' do
    expect(session1.reload.title).to eq('fooooo')
  end

  it { expect(SessionJobs::EditInvitedUsersJob).to have(1).jobs }
end
