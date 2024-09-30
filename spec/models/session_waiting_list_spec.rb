# frozen_string_literal: true
require 'spec_helper'

describe SessionWaitingList do
  describe 'validate uniqueness of session' do
    it 'expects immersive session creates SessionWaitingList' do
      expect { create(:immersive_session) }.to change(described_class, :count).by(1)
    end

    it 'expects unique session-lobby combinations' do
      session = create(:immersive_session)
      expect { create(:session_waiting_list, session: session) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
