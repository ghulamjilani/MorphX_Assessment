# frozen_string_literal: true

require 'spec_helper'

describe Session, '.validation' do
  describe 'main validation' do
    subject { build(:immersive_session) }

    it { is_expected.not_to allow_value(0).for(:duration) }
    it { is_expected.not_to allow_value(4).for(:duration) }
    it { is_expected.not_to allow_value('hey').for(:duration) }

    it { is_expected.to allow_value(60).for(:duration) }
  end

  it 'rejects scheduled in the past time' do
    session = build(:immersive_session, start_at: 20.minutes.ago.beginning_of_hour)
    expect(session).to have(1).error_on(:start_at)
  end

  context 'when immersive session' do
    describe 'number of participants fields' do
      # now we auto assign min_number_of_immersive_and_livestream_participants to max_number_of_immersive_participants if max_number_of_immersive_participants nil
      it 'does not allow zero-s in *_number_of_participants' do
        expect(build(:immersive_session, min_number_of_immersive_and_livestream_participants: 0,
                                         max_number_of_immersive_participants: 0)).to have(0).error_on(:max_number_of_immersive_participants)
      end

      it 'expects both - min&max_number_of_immersive_participants to be present' do
        expect(build(:immersive_session, min_number_of_immersive_and_livestream_participants: 5,
                                         max_number_of_immersive_participants: nil)).to have(0).error_on(:max_number_of_immersive_participants)
      end

      it 'allows valid min numbers' do
        valid_session = build(:immersive_session, min_number_of_immersive_and_livestream_participants: 4,
                                                  max_number_of_immersive_participants: 10)
        expect(valid_session).to have(0).error_on(:min_number_of_immersive_and_livestream_participants)
      end

      it 'allows valid max numbers' do
        valid_session = build(:immersive_session, min_number_of_immersive_and_livestream_participants: 4,
                                                  max_number_of_immersive_participants: 10)
        expect(valid_session).to have(0).error_on(:max_number_of_immersive_participants)
      end

      it 'does not allow max_number_of_immersive_participants to be greater than system parameter' do
        valid_session = build(:immersive_session, min_number_of_immersive_and_livestream_participants: 4,
                                                  max_number_of_immersive_participants: (SystemParameter.max_number_of_immersive_participants + 1))
        expect(valid_session).to have(1).error_on(:max_number_of_immersive_participants)
      end
    end
  end

  describe 'minimum system parameters compliance' do
    let!(:channel) { create(:listed_channel) }

    it 'works' do
      session = build(:immersive_session, channel: channel)
      session.immersive_access_cost = session.immersive_min_access_cost - 1

      expect do
        session.save!
      end.to raise_error(/Immersive access cost must be greater than or equal to #{session.immersive_min_access_cost}/)

      allow(SystemParameter).to receive(:max_group_immersive_session_access_cost).and_return(100)

      create(:immersive_session, channel: channel, immersive_access_cost: 90)
    end
  end

  describe 'maximum system parameters advising' do
    let!(:user) { create(:user) }
    let!(:channel) { create(:channel, presenter: presenter) }
    let(:presenter) { create(:presenter, user: user) }

    it 'works' do
      allow(SystemParameter).to receive(:min_group_immersive_session_access_cost).and_return(0.01)
      allow(SystemParameter).to receive(:max_group_immersive_session_access_cost).and_return(100.01)

      session = build(:immersive_session, channel: channel, immersive_access_cost: 103)
      expect(session).not_to be_valid
    end
  end

  describe 'book ahead max validation' do
    before do
      allow(SystemParameter).to receive(:book_ahead_in_hours_max).and_return(72)
    end

    it {
      expect(build(:immersive_session, start_at: 12.hours.from_now.beginning_of_hour)).to have(0).error_on(:start_at)
    }

    it {
      expect(build(:immersive_session, start_at: 999.hours.from_now.beginning_of_hour)).to have(1).error_on(:start_at)
    }
  end
end
