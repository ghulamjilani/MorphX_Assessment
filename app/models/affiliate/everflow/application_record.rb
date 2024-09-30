# frozen_string_literal: true

class Affiliate::Everflow::ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  self.table_name_prefix = 'affiliate_everflow_'
end
