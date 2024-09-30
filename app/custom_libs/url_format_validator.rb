# frozen_string_literal: true

class UrlFormatValidator < ActiveModel::Validator
  def validate(record)
    return if record.errors.include?(:url)
    return if record.url.blank?

    if (record.url =~ URI::DEFAULT_PARSER.make_regexp).nil?
      record.errors.add(:url, 'does not look like valid URL')
    end
  end
end
