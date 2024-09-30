# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::Session::WebrtcserviceService do
  let(:immersive_session) { build(:published_session) }
  let(:livestream_session) { build(:published_livestream_session) }
  let(:webrtcservice_room) { create(:webrtcservice_room) }

  describe '#webrtcservice_room' do
    let(:immersive_session) { webrtcservice_room.session }

    it { expect { immersive_session.webrtcservice_rooms }.not_to raise_error }

    it { expect(immersive_session.webrtcservice_rooms.where(id: webrtcservice_room.id)).to exist }
  end

  describe '#max_number_of_webrtcservice_participants' do
    it { expect { immersive_session.max_number_of_webrtcservice_participants }.not_to raise_error }
  end

  # rubocop:disable RSpec/PredicateMatcher
  describe '#webrtcservice?' do
    it { expect { immersive_session.webrtcservice? }.not_to raise_error }

    it { expect(immersive_session.webrtcservice?).to be_truthy }

    it { expect(livestream_session.webrtcservice?).to be_falsey }
  end
  # rubocop:enable RSpec/PredicateMatcher

  describe '#unique_webrtcservice_name' do
    let(:immersive_session) { create(:published_session) }

    it { expect { immersive_session.unique_webrtcservice_name }.not_to raise_error }

    it { expect(immersive_session.unique_webrtcservice_name).to be_present }
  end

  describe '#webrtcservice_client' do
    it { expect { immersive_session.webrtcservice_client }.not_to raise_error }
  end

  describe '#activate_webrtcservice_room' do
    let(:immersive_session) { create(:published_session) }

    it { expect { immersive_session.activate_webrtcservice_room }.not_to raise_error }
  end

  describe '#remove_webrtcservice_participant' do
    let(:room_member) { create(:room_member) }
    let(:immersive_session) { room_member.session }

    it { expect { immersive_session.remove_webrtcservice_participant(room_member) }.not_to raise_error }
  end
end
