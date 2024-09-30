# frozen_string_literal: true
class Shop::Product < ActiveRecord::Base
  AFFILIATE_PARTNERS = {}.freeze
  monetize :price_cents, with_model_currency: :price_currency

  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :organization, inverse_of: :products, foreign_key: :organization_uuid, primary_key: :uuid

  has_one :product_image, class_name: 'Shop::ProductImage', dependent: :destroy
  has_many :lists_products, class_name: 'Shop::ListsProduct', dependent: :destroy
  has_many :lists, class_name: 'Shop::List', through: :lists_products
  has_many :attached_lists, class_name: 'Shop::AttachedList', through: :lists
  has_many :stores, dependent: :destroy

  validates :title, presence: true
  validates :url, presence: true, allow_blank: true, format: %r{\Ahttps?://[^\s]+\z}

  accepts_nested_attributes_for :product_image
  accepts_nested_attributes_for :stores

  before_save :format_url

  def as_json(options = {})
    {
      id: id,
      title: title,
      description: description,
      url: short_url(options[:user]),
      affiliate_url: short_url(options[:user]),
      is_affiliate: partner_handler.present?,
      short_description: short_description,
      specifications: specifications,
      price: price.format,
      price_cents: price_cents,
      image_url: image_url
    }
  end

  def image_url
    img = product_image || build_product_image
    img.image_url
  end

  def formatted_url
    format_url
    url
  end

  def share_url(user = nil)
    if user && partner && Product::AFFILIATE_PARTNERS[partner.to_sym]
      partner_handler(user).affiliate_url
    else
      affiliate_url.presence || formatted_url
    end
  end

  def partner_handler(user = nil)
    return nil unless partner && Product::AFFILIATE_PARTNERS[partner.to_sym]

    Product::AFFILIATE_PARTNERS[partner.to_sym].new(url, user.try(:affiliate_signature))
  end

  def short_url(user = nil)
    shortened = Shortener::ShortenedUrl.generate(share_url(user), category: self.class.name, owner: user)
    "https://#{ENV['SHORT_URL_HOST']}/s/#{shortened.unique_key}"
  rescue StandardError # if something went wrong,
    formatted_url
  end

  private

  def format_url
    return '#' unless url

    self.url = "https://#{url}" unless url.start_with?('http')
  end
end
