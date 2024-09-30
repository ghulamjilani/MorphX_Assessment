# frozen_string_literal: true
class PaypalDonation < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :abstract_session, polymorphic: true, touch: true
  belongs_to :user

  serialize :additional_data, Hash

  validates :ipn_track_id, uniqueness: true

  before_validation :extract_mandatory_info

  module TitleAsSingular
    DONATE = 'Donate'
    TIP    = 'Tip'
    GIFT   = 'Gift'

    ALL    = [DONATE, TIP, GIFT].freeze
  end

  private

  def extract_mandatory_info
    # NOTE: see #PaypalUtils.paypal_number & PaypalUtils.decrypt_paypal_number methods to understand this code
    encrypted_data = additional_data[:item_number]
    decrypted = PaypalUtils.decrypt_paypal_number(encrypted_data)

    # 2.2.2 :002 > PaypalUtils.decrypt_paypal_number PaypalDonation.last.additional_data[:item_number]
    #  PaypalDonation Load (1.2ms)  SELECT  "paypal_donations".* FROM "paypal_donations"  ORDER BY "paypal_donations"."id" DESC LIMIT 1
    # => {:model_class=>"Session", :user_id=>71, :model_id=>196}

    if decrypted.present?
      self.user_id               = decrypted.fetch(:user_id)
      self.abstract_session_id   = decrypted.fetch(:model_id)
      self.abstract_session_type = decrypted.fetch(:model_class)
    end
  end
end
