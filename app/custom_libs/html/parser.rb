# frozen_string_literal: true

module Html
  class Parser
    attr_accessor :content
    attr_reader :link_previews

    def initialize(content)
      @content = content
      @link_previews = []
      @doc = Nokogiri::HTML::DocumentFragment.parse(content)
    end

    def wrap_urls(options = {})
      options = options.to_h.deep_symbolize_keys
      html_attributes = options[:html_attributes].to_h.map { |k, v| " #{k}=\"#{v}\"" }.join(' ')

      @doc.xpath('.//text()[not(ancestor::a)] | text()[not(ancestor::a)]').each do |text|
        new_content = text.content
        text.content.scan(%r{(https?://(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?://(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,}|[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,})}).flatten.compact.uniq.each do |match|
          new_content = new_content.gsub(match, "<a href=\"#{match.starts_with?('http') ? match : "https://#{match}"}\"#{html_attributes}>#{match}</a>")
        end
        text.replace(new_content)
      end
      @content = @doc.to_html
      self
    end

    def process_link_previews
      wrap_urls
      @link_previews = []
      @doc.css('a:not([data-link-preview-id])').each do |node|
        next unless (url = SanitizeUrl.sanitize_url(node[:href]))
        next unless (link_preview = LinkPreview.create_or_find_by(url: url))

        node['data-link-preview-id'] = link_preview.id
      end
      @content = @doc.to_html
      get_link_previews
      self
    end

    def get_link_previews
      @link_previews = []
      @doc.css('a[data-link-preview-id]').each do |node|
        if node[:href].present? && node[:href].match(URI::DEFAULT_PARSER.make_regexp)
          link_preview = LinkPreview.find_by(id: node['data-link-preview-id'])
          @link_previews << link_preview if link_preview.present?
        end
      end
      @link_previews
    end

    def remove_scripts
      @doc.css('script').remove
      @doc.xpath("//@*[starts-with(name(),'on')]").remove
      @content = @doc.to_html
      self
    end

    def to_s
      @content.to_s
    end

    def mentioned_user_ids
      @doc.css('span.mention[data-id]').map { |node| node['data-id'].to_i }.compact.uniq
    end

    def process_links
      @doc.css('a:not([data-link-preview-id])').each do |node|
        next unless (url = SanitizeUrl.sanitize_url(node[:href]))

        node[:href] = url.to_s
      end
      @content = @doc.to_html
      self
    end
  end
end
