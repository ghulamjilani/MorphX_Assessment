# frozen_string_literal: true
class Poll::Template::Option < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  self.table_name = 'poll_option_templates'

  belongs_to :poll_template, class_name: 'Poll::Template::Poll'
end
