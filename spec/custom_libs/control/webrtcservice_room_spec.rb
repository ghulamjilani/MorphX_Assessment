# frozen_string_literal: true

require 'spec_helper'

describe Control::WebrtcserviceRoom do
  let(:webrtcservice_room) { build(:webrtcservice_room) }
  let(:control) { described_class.new(webrtcservice_room) }

  before do
    stub_request(:any, /.*webrtcservice.com*/)
      .to_return(status: 200, body: '', headers: {})
  end

  describe '#compositions' do
    it { expect { control.compositions }.not_to raise_error }
  end

  describe '#participants' do
    it { expect { control.participants }.not_to raise_error }
  end

  describe '#presenter_participants' do
    it { expect { control.presenter_participants }.not_to raise_error }
  end

  describe '#presenter_participant_sids' do
    it { expect { control.presenter_participant_sids }.not_to raise_error }
  end

  describe '#presenter_connected?' do
    it { expect { control.presenter_connected? }.not_to raise_error }
  end

  describe '#user_participants' do
    it { expect { control.user_participants }.not_to raise_error }
  end

  describe '#user_participant_sids' do
    it { expect { control.user_participant_sids }.not_to raise_error }
  end

  describe '#recordings' do
    it { expect { control.recordings }.not_to raise_error }
  end

  describe '#layout_recordings' do
    ([nil] + Webrtcservice::Video::Composition::Layouts::ALL).each do |layout|
      it { expect { control.layout_recordings(layout) }.not_to raise_error }
    end
  end

  describe '#create_composition' do
    it { expect { control.create_composition }.not_to raise_error }
  end

  describe '#complete_room' do
    it { expect { control.complete_room }.not_to raise_error }
  end

  describe '#sync_room' do
    it { expect { control.sync_room({ status: 'in-progress' }) }.not_to raise_error }
  end

  describe '#delete_recordings' do
    it { expect { control.delete_recordings }.not_to raise_error }
  end
end
