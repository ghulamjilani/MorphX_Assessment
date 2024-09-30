# frozen_string_literal: true

module ModelConcerns::ActsAsFollowable
  extend ActiveSupport::Concern

  included do
    acts_as_followable
  end

  def user_followers
    followers_by_type('User').not_deleted.order('follows.created_at DESC')
  end

  def count_user_followers
    if attributes.has_key?(__method__.to_s)
      attributes[__method__.to_s]
    else
      super
    end
  end

  def toggle_follow_relative_path
    "#{relative_path}/toggle_follow"
  end
end
