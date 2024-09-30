# frozen_string_literal: true
class IpInfoRecord < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
end
