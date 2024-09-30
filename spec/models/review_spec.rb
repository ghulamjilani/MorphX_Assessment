# frozen_string_literal: true
require 'spec_helper'

describe Review do
  it 'does not allow multiple comments per rating' do
    session_comment = create(:session_review_with_mandatory_rates)
    session = session_comment.commentable

    expect do
      described_class.create!(
        user: session_comment.user,
        title: 'hey',
        overall_experience_comment: 'no way',
        commentable: session
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  context 'when user is banned' do
    let(:room_member_banned) { create(:room_member_banned) }
    let(:comment) do
      build(:session_review_with_mandatory_rates, user: room_member_banned.user, title: 'hey',
                                                  commentable: room_member_banned.session)
    end

    it 'does not allow to save comment' do
      expect { comment.save! }.to raise_error(/You have been banned/)
    end
  end
end
