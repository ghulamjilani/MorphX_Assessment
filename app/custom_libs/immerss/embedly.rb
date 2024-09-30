# frozen_string_literal: true

module Immerss
  class Embedly
    # Return frame html for provided media URL with options. Caching is built in
    #
    # Examples:
    #   Immerss::Embedly.oembed_html(url: 'https://vimeo.com/46807615', maxwidth: 400)
    #   => "<iframe src=\"http://player.vimeo.com/video/46807615\" width=\"400\" height=\"225\" frameborder=\"0\" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>"
    #
    # Returns <String>
    def self.oembed_html(options)
      # oembed(options)[:html]
      oembed(options)[:embedded]
    end

    def self.oembed_thumbnail_url(options)
      # oembed(options)[:thumbnail_url]
      oembed(options)[:img_src]
    end

    # Return oEmbed hash for provided resource with params. Caching is built in
    # This method could be useful when you have custom parameters like :maxwidth along with :url
    #
    # Examples:
    #   Immerss::Embedly.oembed(url: 'https://vimeo.com/46807615')
    #   => {provider_url:"http://vimeo.com/",
    #       description:"x_ajillagaa",
    #       title:"x ajillagaa",
    #       html:
    #        "<iframe src=\"http://player.vimeo.com/video/46807616\" width=\"624\" height=\"352\" frameborder=\"0\" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>",
    #       author_name:"jinhen_gan",
    #       height:352,
    #       width:624,
    #       thumbnail_url:"http://b.vimeocdn.com/ts/326/119/326119626_295.jpg",
    #       thumbnail_width:295,
    #       version:"1.0",
    #       provider_name:"Vimeo",
    #       type:"video",
    #       thumbnail_height:166,
    #       author_url:"http://vimeo.com/user10059859"}
    #
    # Returns <Hash>
    def self.oembed_old(options)
      raise ArgumentError if options[:url].blank?

      Rails.cache.fetch("oembed:#{ENV['EMBEDLY_API_KEY']}:#{options[:url]}", expires_in: 24.hours) do
        client = ::Embedly::API.new key: ENV['EMBEDLY_API_KEY'], user_agent: 'Mozilla/5.0 (compatible; Immerss/1.0)'

        oembed = client.oembed(options)
        oembed[0].marshal_dump.tap do |response|
          Rails.logger.info "[Embed.ly] requested url: #{options[:url]}, response: #{response.inspect}"
        end
      end
    rescue StandardError => e
      {}
    end

    def self.oembed(options)
      raise ArgumentError if options[:url].blank?

      Rails.cache.fetch("embed:#{options.to_json}", expires_in: 24.hours) do
        @url = URI.parse(options[:url])
        @url.scheme ||= 'http'
        raise ArgumentError if @url.host.blank?

        @result = { url: @url.to_s }
        resp = open(@url)
        if resp.content_type.starts_with?('image/')
          @result[:type] = ChannelLink::OembedTypes::PHOTO
        else
          host = @url.host.gsub(/^www\./, '')
          doc = Nokogiri::HTML(resp)
          @result[:title] = begin
            doc.search("meta[property*='title']").first.attributes['content'].value
          rescue StandardError
            nil
          end
          @result[:description] =
            begin
              doc.search("meta[property*='description']").first.attributes['content'].value
            rescue StandardError
              @result[:title]
            end
          @result[:img_src] = begin
            doc.search("meta[property='og:image']").first.attributes['content'].value
          rescue StandardError
            nil
          end
          if @result[:img_src]
            img_url = URI.parse(@result[:img_src])
            img_url.host ||= @url.host
            img_url.scheme ||= @url.scheme
            @result[:img_src] = img_url.to_s
          end
          if ['youtu.be', 'youtube.com', 'vimeo.com'].include?(host)
            if ['youtu.be', 'youtube.com'].include?(host)
              regex = %r{(?:www\.)?(youtube.com/(watch\?v=|v/)|youtu.be/)(?<vid>[^?&"'>]+)}
              vtype = 'youtube'
            else
              regex = %r{((?:player|www)\.)?vimeo.com/(channels/(\w+/)?|groups/([^/]*)/videos/|album/(\d+)/video/|video/|)(?<vid>\d+)(?:[\w\-]*)}
              vtype = 'vimeo'
            end
            res = regex.match(options[:url])
            if res && res[:vid]
              @result[:type] = ChannelLink::OembedTypes::VIDEO
              width = options[:maxwidth].to_i || 480
              height = width / 16 * 9
              if vtype == 'youtube'
                @result[:url] = "https://www.youtube.com/watch?v=#{res[:vid]}"
                @result[:embedded] =
                  "<iframe class=\"embedly-embed\" src=\"https://www.youtube.com/embed/#{res[:vid]}\" width=\"#{width}\" height=\"#{height}\" scrolling=\"no\" frameborder=\"0\" allowfullscreen=\"\"></iframe>"
                # @result[:img_src] = "https://i.ytimg.com/vi/#{res[:vid]}/hqdefault.jpg"
              else
                @result[:url] = "https://vimeo.com/#{res[:vid]}"
                @result[:embedded] =
                  "<iframe class=\"embedly-embed\" src=\"https://player.vimeo.com/video/#{res[:vid]}\" width=\"#{width}\" height=\"#{height}\" scrolling=\"no\" frameborder=\"0\" allowfullscreen=\"\"></iframe>"
                # @result.merge!(vimeo_info(res[:vid]))
              end
            else
              @result[:type] = ChannelLink::OembedTypes::LINK
            end
          else
            @result[:type] = ChannelLink::OembedTypes::LINK
          end
        end
        @result
      end
    rescue StandardError => e
      {
        url: options[:url],
        type: ChannelLink::OembedTypes::LINK
      }
    end

    # Return oEmbed hash for provided resource. Caching is built in
    #
    # Examples:
    #   Immerss::Embedly.oembed_from_url('https://vimeo.com/46807615')
    #   => {provider_url:"http://vimeo.com/",
    #       description:"x_ajillagaa",
    #       title:"x ajillagaa",
    #       html:
    #        "<iframe src=\"http://player.vimeo.com/video/46807616\" width=\"624\" height=\"352\" frameborder=\"0\" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>",
    #       author_name:"jinhen_gan",
    #       height:352,
    #       width:624,
    #       thumbnail_url:"http://b.vimeocdn.com/ts/326/119/326119626_295.jpg",
    #       thumbnail_width:295,
    #       version:"1.0",
    #       provider_name:"Vimeo",
    #       type:"video",
    #       thumbnail_height:166,
    #       author_url:"http://vimeo.com/user10059859"}
    #
    # Returns <Hash>
    def self.oembed_from_url(url)
      oembed(url: url)
    end

    def self.vimeo_info(id)
      url = "http://vimeo.com/api/v2/video/#{id}.json"
      begin
        resp = Net::HTTP.get_response(URI.parse(url))
        json = JSON.parse(resp.body)
        json = json.first
        {
          url: json['url'],
          title: json['title'],
          description: json['description'],
          img_src: json['thumbnail_large']
        }
      rescue StandardError
        {}
      end
    end
  end
end
