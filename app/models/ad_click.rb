# frozen_string_literal: true
class AdClick < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions
  belongs_to :user, optional: true
  belongs_to :ad_banner, class_name: 'PageBuilder::AdBanner', foreign_key: :pb_ad_banner_id
end
