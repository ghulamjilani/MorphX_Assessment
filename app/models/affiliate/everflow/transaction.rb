# frozen_string_literal: true
class Affiliate::Everflow::Transaction < Affiliate::Everflow::ApplicationRecord
  belongs_to :user
end
