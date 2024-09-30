# frozen_string_literal: true

module Sender
  class TransferServer
    def self.client
      new
    end

    def initialize
      @s3_key           = ENV['QENCODE_S3_ACCESS_KEY_ID']
      @s3_secret        = ENV['QENCODE_S3_SECRET_ACCESS_KEY']
      @s3_region        = (ENV['S3_REGION'] || 'us-west-2')
      @s3_bucket        = ENV['S3_BUCKET_VOD']
      @callback_url = "#{ENV['PROTOCOL']}#{ENV['HOST']}/webhook/v1/transfer_server"
      @client = Excon.new(ENV['CDN_URL'],
                          headers: {
                            'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(
                              ENV['CDN_LOGIN'], ENV['CDN_PASSWORD']
                            ),
                            'Content-Type' => 'application/json',
                            'Accept' => 'application/json'
                          },
                          debug_request: !Rails.env.production?,
                          debug_response: !Rails.env.production?,
                          ssl_verify_peer: false)
    end

    # {url: video.ffmpegservice_download_url, path: "#{video.user_id}/#{video.room_id}", ident: video.id}
    # {url: video.zoom_download_url, path: "#{video.user_id}/#{video.room_id}", ident: video.id}
    def transfer(params)
      @method = :post
      @path = '/storage/files/transfer'
      @expected_status = [200]
      @query = {
        aws_key: @s3_key,
        aws_secret: @s3_secret,
        aws_region: @s3_region,
        from_url: params[:url],
        s3_to_path: params[:path],
        s3_bucket: @s3_bucket,
        callback_url: "#{@callback_url}/#{params[:ident]}",
        service: params[:service]
      }.compact
      sender
    end

    private

    def sender
      @client.request(expects: @expected_status, method: @method, path: @path, query: @query.is_a?(Hash) ? @query : {})
    end
  end
end
