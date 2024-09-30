# frozen_string_literal: true
class Poll::Template::Poll < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  self.table_name = 'poll_templates'

  belongs_to :organization
  belongs_to :user
  has_many :options, class_name: 'Poll::Template::Option', dependent: :destroy, foreign_key: :poll_template_id, primary_key: :id
  has_many :polls, class_name: 'Poll::Poll', dependent: :destroy, foreign_key: :poll_template_id, primary_key: :id
  has_many :votes, class_name: 'Poll::Vote', through: :polls
  accepts_nested_attributes_for :options, allow_destroy: true

  def uniq_votes
    polls.sum(&:uniq_votes)
  end
end
