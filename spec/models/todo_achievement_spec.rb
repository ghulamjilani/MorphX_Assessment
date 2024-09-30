# frozen_string_literal: true
require 'spec_helper'

describe TodoAchievement do
  let(:user) { create(:participant).user }

  describe '#all_checked_for?(user)' do
    it 'works' do
      expect do
        [TodoAchievement::Types::REFERRED_FIVE_FRIENDS, TodoAchievement::Types::SHARE_A_SESSION,
         TodoAchievement::Types::PARTICIPATE_IN_A_SESSION, TodoAchievement::Types::REVIEW_A_SESSION].each do |type|
          described_class.create(user: user, type: type)
        end
      end.to change { described_class.all_checked_for?(user.reload) }.from(false).to(true)
    end
  end

  describe 'when all achievements are present' do
    it 'gives extract credit to user' do
      expect do
        [TodoAchievement::Types::REFERRED_FIVE_FRIENDS, TodoAchievement::Types::SHARE_A_SESSION,
         TodoAchievement::Types::PARTICIPATE_IN_A_SESSION, TodoAchievement::Types::REVIEW_A_SESSION].each do |type|
          described_class.create(user: user, type: type)
        end
      end.to change(LogTransaction, :count).by(1)
    end

    it 'transaction is printable' do
      [TodoAchievement::Types::REFERRED_FIVE_FRIENDS, TodoAchievement::Types::SHARE_A_SESSION,
       TodoAchievement::Types::PARTICIPATE_IN_A_SESSION, TodoAchievement::Types::REVIEW_A_SESSION].each do |type|
        described_class.create(user: user, type: type)
      end
      expect { LogTransaction.last.as_html }.not_to raise_error
    end
  end
end
