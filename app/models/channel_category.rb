# frozen_string_literal: true
class ChannelCategory < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  has_many :channels, foreign_key: 'category_id'

  validates :name, presence: true

  before_destroy :validate_before_destroy

  def validate_before_destroy
    if id == ChannelCategory.default_category.id
      errors.add :base, 'Channel category could not be destroyed'
      throw(:abort)
    end

    reassign_channels_to_default_cat
  end

  def reassign_channels_to_default_cat
    channels.update_all(category_id: ChannelCategory.default_category.id)
  end

  def self.default_category
    find_or_create_by(name: 'Uncategorized')
  end
end
