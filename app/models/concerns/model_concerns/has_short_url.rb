# frozen_string_literal: true

module ModelConcerns::HasShortUrl
  extend ActiveSupport::Concern

  included do
    has_shortened_urls
  end

  def recreate_short_urls
    generate_short_url
    generate_ref_short_url
  end

  def update_short_urls
    update_short_url
    update_ref_short_url
  end

  def fetch_short_url
    if short_url_needs_update?
      update_short_url
    else
      short_url
    end
  end

  def fetch_ref_short_url
    if ref_short_url_needs_update?
      update_ref_short_url
    else
      referral_short_url
    end
  end

  def generate_shortened_url(url)
    s = Shortener::ShortenedUrl.generate(url, category: self.class.name, owner: self)
    "https://#{ENV['SHORT_URL_HOST']}/s/#{s.unique_key}"
  end

  def generate_short_url
    su = generate_shortened_url(absolute_path(nil, nil))
    update(short_url: su)
    su
  end

  def generate_ref_short_url
    rsu = generate_shortened_url(absolute_path(nil, organizer))
    update(referral_short_url: rsu)
    rsu
  end

  def short_url_needs_update?
    shortened_url_needs_update?(s_url: short_url, url: absolute_path(nil, nil))
  end

  def ref_short_url_needs_update?
    shortened_url_needs_update?(s_url: short_url, url: absolute_path(nil, organizer))
  end

  def shortened_url_needs_update?(s_url:, url:)
    shortened_url = Shortener::ShortenedUrl.find_by(unique_key: shortened_url_unique_key(s_url))
    return true if shortened_url.blank?
    return true if shortened_url.url != url

    return false
  end

  def update_short_url
    url = absolute_path(nil, nil)
    su_unique_key = shortened_url_unique_key(short_url)
    shortened_url = Shortener::ShortenedUrl.find_by(unique_key: su_unique_key)
    if shortened_url.present?
      shortened_url.update_columns(url: url) if shortened_url.url != url
      shortened_url.url
    else
      generate_short_url
    end
  end

  def update_ref_short_url
    url = absolute_path(nil, organizer)
    rsu_unique_key = shortened_url_unique_key(referral_short_url)
    shortened_url = Shortener::ShortenedUrl.find_by(unique_key: rsu_unique_key)
    if shortened_url.present?
      shortened_url.update_columns(url: url) if shortened_url.url != url
      shortened_url.url
    else
      generate_ref_short_url
    end
  end

  def shortened_url_unique_key(s_url)
    m = s_url.to_s.match short_url_unique_key_regexp
    return nil unless m

    return m[0]
  end

  private

  def short_url_unique_key_regexp
    quoted_base = Regexp.quote "#{ENV['SHORT_URL_HOST']}/s/"
    Regexp.new("(?<=#{quoted_base}).*")
  end
end
