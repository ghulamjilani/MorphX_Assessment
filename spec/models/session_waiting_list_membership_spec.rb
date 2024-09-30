# frozen_string_literal: true
require 'spec_helper'

describe SessionWaitingListMembership do
  describe 'validators' do
    it 'expects unique waiting+list-user combinations' do
      session_waiting_list = create(:session_waiting_list)

      user1 = create(:user)
      session_waiting_list.users << user1
      session_waiting_list.users << create(:user)

      expect { session_waiting_list.users << user1 }.to raise_error(/already been taken/)
    end
  end
end
