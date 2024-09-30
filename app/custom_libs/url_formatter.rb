# frozen_string_literal: true

module UrlFormatter
  def self.included(base)
    base.send(:before_validation, :format_url)
  end

  def format_url
    return if url.nil?

    self.url = url.strip

    uri = URI.parse(url)
    self.url = "https://#{url}" if uri.scheme.blank? && url.present?
  end
end
