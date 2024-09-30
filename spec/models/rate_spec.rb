# frozen_string_literal: true
require 'spec_helper'

describe Rate do
  context 'when user is banned' do
    let(:room_member_banned) { create(:room_member_banned) }
    let(:rate) do
      build(:session_review_with_mandatory_rates, user: room_member_banned.user, title: 'hey',
                                                  commentable: room_member_banned.session)
    end

    it 'does not allow to save comment' do
      expect { rate.save! }.to raise_error(/You have been banned/)
    end
  end
end
