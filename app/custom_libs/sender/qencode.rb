# frozen_string_literal: true

module Sender
  class Qencode
    class << self
      def client(params = {})
        new(params)
      end
    end

    def initialize(params = {})
      raise 'Add api key' if ENV['QENCODE_API_KEY'].blank? && !Rails.env.test?

      @qencode_api_key  = ENV['QENCODE_API_KEY']
      @api_domain       = "#{ENV['PROTOCOL']}#{ENV['HOST']}"
      @s3_key           = ENV['QENCODE_S3_ACCESS_KEY_ID']
      @s3_secret        = ENV['QENCODE_S3_SECRET_ACCESS_KEY']
      @s3_sub_domain    = Rails.env.development? ? 's3' : 's3-us-west-2'
      @domain_bucket    = "s3://#{@s3_sub_domain}.amazonaws.com/#{ENV['S3_BUCKET_VOD']}"
      @expected_status  = [200, 201]
      @skip_raise = params[:skip_raise]
      @method = :post
      @client = Excon.new('https://api.qencode.com',
                          headers: {
                            'Content-Type' => 'application/x-www-form-urlencoded',
                            'Accept' => 'application/json'
                          },
                          debug_request: !Rails.env.production?,
                          debug_response: !Rails.env.production?)
    end

    def access_token
      @path = '/v1/access_token'
      @body = URI.encode_www_form(
        api_key: @qencode_api_key
      )
      sender[:token]
    end

    def create_task
      token = access_token
      @path = '/v1/create_task'
      @body = URI.encode_www_form(
        token: token
      )
      sender[:task_token]
    end

    def start_encode2(params)
      set_width_height(params: params)
      task_token = create_task
      body = {
        task_token: task_token,
        query: { query: {
          source: params[:url],
          callback_url: params[:callback_url] || "#{@api_domain}/webhook/v1/qencode/video",
          upscale: 1,
          encoder_version: 2,
          format: ([
            {
              output: 'advanced_hls',
              destination: {
                url: "#{@domain_bucket}#{params[:s3_main_path].start_with?('/') ? params[:s3_main_path] : "/#{params[:s3_main_path]}"}",
                key: @s3_key,
                secret: @s3_secret,
                permissions: 'public-read'
              },
              segment_duration: 6,
              duration: params[:duration],
              start_time: params[:start_time] || 0,
              stream: stream_array,
              tag: 'main'
            },
            {
              output: 'advanced_hls',
              destination: {
                url: "#{@domain_bucket}#{params[:s3_preview_path].start_with?('/') ? params[:s3_preview_path] : "/#{params[:s3_preview_path]}"}",
                key: @s3_key,
                secret: @s3_secret,
                permissions: 'public-read'
              },
              segment_duration: 6,
              duration: preview_duration(params),
              start_time: params[:start_time] || 0,
              stream: stream_array,
              tag: 'preview'
            }
          ] + thumbnail_array(params: params))
        } }.to_json,
        payload: params[:video_id]
      }

      @path = '/v1/start_encode2'
      @body = URI.encode_www_form(body)
      sender
      task_token
    end

    def statuses(task_tokens)
      task_tokens = task_tokens.compact.map(&:to_s).join(',') if task_tokens.is_a?(Array)
      @path = '/v1/status'
      @body = URI.encode_www_form(task_tokens: task_tokens)
      sender[:statuses]
    end

    def status(task_token)
      statuses(task_token)[task_token]
    end

    def request(params)
      @skip_raise = params[:skip_raise] || @skip_raise
      @path = params[:path]
      @method = params[:method] || :post
      @expected_status = params[:expected_status] || [200, 201]
      @body = URI.encode_www_form(params[:body]) if params[:body]
      sender
    end

    private

    def set_width_height(params:)
      @width = 1920
      @height = 1080
      @width   = params[:width].to_i   if params[:width].to_i.positive?
      @height  = params[:height].to_i  if params[:height].to_i.positive?
      @vertical = @width < @height
    end

    def stream_array
      video_temp = { '360' => '640', '480' => '854', '720' => '1280', '1080' => '1920' }
      audio_temp = { '360' => '128', '480' => '128', '720' => '320',  '1080' => '320' }
      max_resolution = @vertical ? @width : @height
      max_resolution = 360 if max_resolution < 360
      resolutions = [360, 480, 720, 1080].select { |obj| obj <= max_resolution }
      resolutions.map do |obj|
        {
          size: (@vertical ? "#{obj}x#{video_temp[obj.to_s]}" : "#{video_temp[obj.to_s]}x#{obj}"),
          audio_bitrate: audio_temp[obj.to_s]
        }
      end
    end

    def thumbnail_array(params:)
      horizontals = [
        { width: 1920, height: 1080, filename: '19201080.jpg' },
        { width: 105,   height: 60,   filename: '10560.jpg'     },
        { width: 920,   height: 500,  filename: '920500.jpg'    },
        { width: 410,   height: 230,  filename: '410230.jpg'    }
      ]

      verticals = [
        { width: 607, height: 1080, filename: '19201080.jpg' },
        { width: 34,  height: 60,   filename: '10560.jpg'     },
        { width: 281, height: 500,  filename: '920500.jpg'    },
        { width: 129, height: 230,  filename: '410230.jpg'    }
      ]

      result = []
      (@vertical ? verticals : horizontals).each do |res|
        %w[0.01 0.05 0.15 0.70 0.99].each.with_index do |time, index|
          result.push({
                        output: 'thumbnail',
                        time: time,
                        width: res[:width],
                        height: res[:height],
                        image_format: 'jpg',
                        destination: {
                          url: "#{@domain_bucket}#{params[:s3_preview_path].start_with?('/') ? params[:s3_preview_path] : "/#{params[:s3_preview_path]}"}/images/#{index}/#{res[:filename]}",
                          key: @s3_key,
                          secret: @s3_secret,
                          permissions: 'public-read'
                        },
                        user_tag: "#{time.delete('.').delete('0')}_#{res[:width]}x#{res[:height]}"
                      })
        end
      end
      result
    end

    def preview_duration(params)
      params[:duration] > 60 ? 60 : params[:duration] / 2
    end

    def sender
      response = @client.request(expects: @expected_status, method: @method, path: @path, body: @body, query: @query)
      hash = JSON.parse(response.body).with_indifferent_access

      raise ::Qencode::Errors::ServiceSuspendedError if hash[:error] == 6 && !@skip_raise
      raise "QENCODE #{hash[:error]} - #{hash[:message]}" if hash[:error] != 0 && !@skip_raise

      hash
    end
  end
end
