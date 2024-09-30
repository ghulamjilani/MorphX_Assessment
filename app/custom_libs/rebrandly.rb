# frozen_string_literal: true

class Rebrandly
  URL = 'https://api.rebrandly.com/v1/links'
  def initialize(url, title)
    @url = URI.parse(url)
    @title = title
  end

  def short_url
    body = {
      destination: @url.to_s,
      title: @title,
      domain: { 'fullName': ENV['REBRANDLY_DOMAIN'] }
      # slashtag: "A_NEW_SLASHTAG",
    }.to_json
    headers = {
      'Content-Type': 'application/json',
      apikey: ENV['REBRANDLY_KEY']
    }
    resp = Excon.post(URL, body: body, headers: headers)

    data = JSON.parse(resp.body)
    data['shortUrl']
  end
end
