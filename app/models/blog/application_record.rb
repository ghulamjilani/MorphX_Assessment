# frozen_string_literal: true

class Blog::ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  self.table_name_prefix = 'blog_'
end
