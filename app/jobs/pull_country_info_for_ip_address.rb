# frozen_string_literal: true

class PullCountryInfoForIpAddress < ApplicationJob
  def perform(ip)
    return if IpInfoRecord.exists?(ip: ip)

    hash = HTTParty.get("https://ipinfo.io/#{ip}?token=42576d359578ce", timeout: 3).to_hash
    attrs = hash.slice(*IpInfoRecord.new.attributes.keys)

    IpInfoRecord.new(attrs).save!
  end
end
