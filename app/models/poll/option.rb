# frozen_string_literal: true
class Poll::Option < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  self.table_name = 'poll_options'

  belongs_to :poll, class_name: 'Poll::Poll'
  has_many :votes, class_name: 'Poll::Vote', dependent: :destroy, foreign_key: :poll_option_id, primary_key: :id

  def is_voted?(user_id)
    return false unless user_id

    votes.exists?(user_id: user_id)
  end
end
