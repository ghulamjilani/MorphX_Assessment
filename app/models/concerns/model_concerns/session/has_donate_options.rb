# frozen_string_literal: true

module ModelConcerns::Session::HasDonateOptions
  extend ActiveSupport::Concern

  included do
    scope :with_paypal_donation_options, lambda {
                                           where('donate_video_tab_content_in_markdown_format IS NOT NULL AND donate_video_tab_options_in_csv_format IS NOT NULL')
                                         }

    has_many :paypal_donations, as: :abstract_session, dependent: :destroy

    before_validation do
      if donate_video_tab_content_in_markdown_format.present? && donate_video_tab_options_in_csv_format.blank?
        self.donate_video_tab_options_in_csv_format = '1,5,10'
      end
    end

    validate :donate_video_tab_options_in_csv_format_compliance
  end

  def total_donations_amount
    paypal_donations.inject(0) do |result, paypal_donation|
      result += BigDecimal(paypal_donation.additional_data[:payment_gross])
      result
    end
  end

  private

  def donate_video_tab_options_in_csv_format_compliance
    return if donate_video_tab_options_in_csv_format.blank?

    if donate_video_tab_options_in_csv_format.parse_csv.size != 3
      errors.add(:donate_video_tab_options_in_csv_format, 'has to contain 3 integers separated by comma signs')
    end
  end
end
