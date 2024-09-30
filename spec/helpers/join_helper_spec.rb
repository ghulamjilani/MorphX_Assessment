# frozen_string_literal: true

require 'spec_helper'

describe JoinHelper do
  describe '#nearest_abstract_session' do
    let(:session) { create(:immersive_session) }
    let(:current_user) { create(:user) }
    let(:helper1) do
      helper = Object.new
      helper.extend described_class
      helper
    end

    before do
      allow(current_user).to receive(:nearest_abstract_session).and_return(session)
      allow(helper1).to receive(:current_user).and_return(current_user)
    end

    it { expect(helper1.nearest_abstract_session).to eq(session) }

    it 'works' do
      session.room.destroy!
      allow(helper1).to receive(:current_user).and_return(current_user)
      allow(current_user).to receive(:nearest_abstract_session).and_return(session.reload)
      expect(helper1.nearest_abstract_session).to eq(nil)
    end
  end
end
