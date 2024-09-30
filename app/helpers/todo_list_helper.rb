# frozen_string_literal: true

module TodoListHelper
  def last_todo_update_at
    hashes = current_user.todo_achievements_as_hashes
    hashes.present? ? hashes.last['created_at'] : current_user.created_at
  end

  # return [String] - example "Great job completing your first task, five more to go!"
  def n_more_todo_tasks_message
    humanized1 = {
      # 5 => "fifth",
      4 => 'fourth',
      3 => 'third',
      2 => 'second',
      1 => 'first'
    }

    humanized2 = {
      # 5 => "five",
      4 => 'four',
      3 => 'three',
      2 => 'two',
      1 => 'one'
    }

    completed = current_user.todo_achievements_as_hashes.size + 1
    more = 5 - completed
    "Great job completing your #{humanized1[completed]} task, #{humanized2[more]} more to go!"
  end

  def pluralize_no_digits(*args)
    pluralized = pluralize(*args)
    pluralized.gsub(/\d\s?/, '')
  end

  def remainig_todo_task_count
    # NOTE: not "6 - " because for Sign Up there is no need to create a todo achievement
    5 - current_user.todo_achievements_as_hashes.size
  end

  def referred_five_friends_completed?
    current_user.todo_achievements_as_hashes.detect do |h|
      h['type'] == TodoAchievement::Types::REFERRED_FIVE_FRIENDS
    end.present?
  end

  def referred_five_friends_completed_at
    current_user.todo_achievements_as_hashes.detect do |h|
      h['type'] == TodoAchievement::Types::REFERRED_FIVE_FRIENDS
    end['created_at']
  end

  def share_a_session_completed?
    current_user.todo_achievements_as_hashes.detect do |h|
      h['type'] == TodoAchievement::Types::SHARE_A_SESSION
    end.present?
  end

  def share_a_session_completed_at
    current_user.todo_achievements_as_hashes.detect do |h|
      h['type'] == TodoAchievement::Types::SHARE_A_SESSION
    end['created_at']
  end

  def participate_in_a_session_completed?
    current_user.todo_achievements_as_hashes.detect do |h|
      h['type'] == TodoAchievement::Types::PARTICIPATE_IN_A_SESSION
    end.present?
  end

  def participate_in_a_session_completed_at
    current_user.todo_achievements_as_hashes.detect do |h|
      h['type'] == TodoAchievement::Types::PARTICIPATE_IN_A_SESSION
    end['created_at']
  end

  def review_a_session_completed?
    current_user.todo_achievements_as_hashes.detect do |h|
      h['type'] == TodoAchievement::Types::REVIEW_A_SESSION
    end.present?
  end

  def review_a_session_completed_at
    current_user.todo_achievements_as_hashes.detect do |h|
      h['type'] == TodoAchievement::Types::REVIEW_A_SESSION
    end['created_at']
  end
end
