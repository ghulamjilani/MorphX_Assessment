# frozen_string_literal: true
class Shop::List < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :organization

  has_many :lists_products, class_name: 'Shop::ListsProduct', dependent: :destroy
  has_many :products, through: :lists_products
  has_many :attached_lists, class_name: 'Shop::AttachedList', dependent: :destroy
  validates :name, presence: true

  def as_json(_options = {})
    {
      id: id,
      name: name,
      description: description,
      url: url,
      products: products.as_json(user: organization.user),
      selected: selected
    }
  end

  def primary_image
    @product = products.limit(1).first || ::Shop::Product.new
    @product.image_url
  end
end
