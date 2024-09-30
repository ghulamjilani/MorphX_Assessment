# frozen_string_literal: true

require 'spec_helper'

describe Webrtcservice::Video::Composition do
  let(:presenter_sids) { (1..4).to_a.map { SecureRandom.hex(10) } }
  let(:user_sids) { (1..4).to_a.map { SecureRandom.hex(10) } }

  describe '.layout_parameters' do
    Webrtcservice::Video::Composition::Layouts::ALL.each do |layout|
      context "when layout is #{layout}" do
        it { expect { described_class.layout_parameters(layout:, presenter_sids:, user_sids:) }.not_to raise_error }

        it { expect(described_class.layout_parameters(layout:, presenter_sids:, user_sids:)).to be_present }
      end
    end
  end

  describe '.parameters_presenter_only' do
    it { expect { described_class.parameters_presenter_only(presenter_sids:, user_sids:) }.not_to raise_error }

    it { expect(described_class.parameters_presenter_only(presenter_sids:, user_sids:)).to be_present }
  end

  describe '.parameters_presenter_focus' do
    it { expect { described_class.parameters_presenter_focus(presenter_sids:, user_sids:) }.not_to raise_error }

    it { expect(described_class.parameters_presenter_focus(presenter_sids:, user_sids:)).to be_present }
  end

  describe '.parameters_grid' do
    it { expect { described_class.parameters_grid }.not_to raise_error }

    it { expect(described_class.parameters_grid).to be_present }
  end
end
