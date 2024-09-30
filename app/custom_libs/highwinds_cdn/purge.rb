# frozen_string_literal: true

module HighwindsCdn
  class Purge
    BASE_URL = 'https://striketracker.highwinds.com/api/v1'

    class << self
      # Provide `recursive: true` if you want to purge a folder
      def purge_url(urls, recursive: false)
        body = { list: urls.map { |u| { url: u, recursive: recursive } } }.to_json
        p body
        headers = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'Authorization' => authorization_header
        }
        resp = Excon.post(BASE_URL + "/accounts/#{ENV['HW_CDN_ACCOUNT']}/purge", body: body, headers: headers)

        puts 'purge_url'
        puts resp.body
        data = JSON.parse(resp.body)
        check_error(data)
        data['id']
      end

      private

      def authorization_header
        "Bearer #{ENV['HW_CDN_TOKEN']}"
      end

      def check_error(data)
        puts "Error: #{data['error']}" if data['error']
      end
    end
  end
end
