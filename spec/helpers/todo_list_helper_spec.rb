# frozen_string_literal: true

require 'spec_helper'

describe TodoListHelper do
  describe '#n_more_todo_tasks_message' do
    let(:current_user) { create(:user) }
    let(:helper) do
      helper = Object.new
      helper.extend described_class
      helper
    end

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    it 'works for beginners' do
      expect(helper.n_more_todo_tasks_message).to eq('Great job completing your first task, four more to go!')
    end

    it 'works on last step' do
      TodoAchievement.create(user: current_user, type: TodoAchievement::Types::REFERRED_FIVE_FRIENDS)
      TodoAchievement.create(user: current_user, type: TodoAchievement::Types::SHARE_A_SESSION)
      TodoAchievement.create(user: current_user, type: TodoAchievement::Types::PARTICIPATE_IN_A_SESSION)
      expect(helper.n_more_todo_tasks_message).to eq('Great job completing your fourth task, one more to go!')
    end
  end
end
