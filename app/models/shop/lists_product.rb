# frozen_string_literal: true
class Shop::ListsProduct < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :list, class_name: 'Shop::List'
  belongs_to :product, class_name: 'Shop::Product'

  validates :product_id, uniqueness: { scope: :list_id }

  after_create :cable_notification_product_added

  def cable_notification_product_added
    ListsChannel.broadcast_to list, event: 'product_added', data: { product_id: product_id, list_id: list_id }
  end
end
