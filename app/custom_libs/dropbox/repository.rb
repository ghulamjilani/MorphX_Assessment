# frozen_string_literal: true

module Dropbox
  class Repository
    attr_reader :current_user, :dropbox_client

    alias_method :client, :dropbox_client

    def initialize(user)
      @current_user = user
      _get_client
    end

    # Public: read child elements of :root_dir
    #
    # Returns Array(Hash, Hash).
    # Raises DropboxError.
    # [{"rev" => "1f5019d3183", "thumb_exists"=>false, "path" => "/5-31-2015 3-12-13 PM.mp4", "is_dir"=>false, "client_mtime" => "Thu, 04 Jun 2015 22:49:31 +0000", "icon" => "page_white_film", "read_only"=>false, "modifier"=>nil, "bytes"=>5481821, "modified" => "Thu, 04 Jun 2015 22:49:30 +0000", "size" => "5.2 MB", "root" => "dropbox", "mime_type" => "video/mp4", "revision"=>501}]

    def read_dir(root_dir)
      contents = @dropbox_client.metadata(root_dir)['contents']
      contents.delete_if do |o|
        file_type = File.extname(o['path'].to_s).delete('.')
        !o['is_dir'] && DropboxMaterial::FileTypes::ALL.exclude?(file_type)
      end
      contents
    end

    # Public: get url to media file
    #
    # Returns Hash.
    # Raises DropboxError.
    def get_media(path)
      # media example: {"url"=> "https://dl.dropbox.com/0/view/kepjtjyjsxzjq12/file.png", expires: "Tue, 01 Jan 2030 00:00:00 +0000"}
      # 4 hours is a period of url's lifetime
      Rails.cache.fetch("dropbox_media:#{@current_user.id}:#{path}", expires_in: 4.hours) do
        @dropbox_client.media(path)['url']
      end
    end

    def reload_client
      @dropbox_client = nil
      _get_client
    end

    def dropbox_asset(path)
      Rails.cache.fetch("dropbox_metadata:#{@current_user.id}:#{path}", expires_in: 2.minutes) do
        @dropbox_client.metadata(path)
      end
    end

    def dropbox_assets(root_dir = nil)
      root_dir ||= '.'
      raw_assets = raw_dropbox_assets(root_dir)
      if display_level_up_element?(root_dir)
        raw_assets.unshift(level_up_element(root_dir))
      else
        raw_assets
      end
    end

    private

    def _get_client
      if current_user.dropbox_token.present?
        @dropbox_client ||= begin
          dropbox_session = DropboxSession.deserialize(current_user.dropbox_token)
          DropboxClient.new(dropbox_session, :dropbox)
        rescue DropboxAuthError, DropboxError => e
          Rails.logger.warn e.message
          # The stored session didn't work.  Fall through and start OAuth.
          current_user.update_attribute :dropbox_token, nil
          nil
        end
      end
    end

    def level_up_element(root_dir)
      Asset.new({ 'path' => upper_level_path(root_dir), 'back' => true, 'is_dir' => true }).as_json
    end

    # Returns Array[Hash, Hash]
    def raw_dropbox_assets(root_dir)
      Rails.cache.fetch("dropbox_assets:#{@current_user.id}:#{root_dir}", expires_in: 2.minutes) do
        read_dir(root_dir).map { |asset| Asset.new(asset).as_json }
      end
    end

    def upper_level_path(root_dir)
      path_names = root_dir.split('/')
      path_names.first(path_names.length - 1).join('/').tap do |result|
        result << '.' if result.blank?
      end
    end

    def display_level_up_element?(root_dir)
      root_dir != '.' && root_dir != '/'
    end
  end
end
