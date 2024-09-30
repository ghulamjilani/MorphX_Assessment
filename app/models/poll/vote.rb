# frozen_string_literal: true
class Poll::Vote < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  self.table_name = 'poll_votes'

  belongs_to :poll_option, class_name: 'Poll::Option', counter_cache: :votes_count
  belongs_to :user
  has_one :poll, through: :poll_option
end
