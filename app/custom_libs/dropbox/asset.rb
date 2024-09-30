# frozen_string_literal: true

require 'forwardable'
module Dropbox
  class Asset
    DEFAULT_KEYS = { 'revision' => nil, 'rev' => nil, 'thumb_exists' => nil, 'bytes' => nil, 'modified' => nil,
                     'path' => nil, 'is_dir' => nil, 'icon' => nil, 'root' => nil, 'size' => nil, 'back' => nil, 'mime_type' => nil }.freeze

    attr_reader :asset_info

    delegate(*DEFAULT_KEYS.keys, to: :asset_info)
    # Public: create model from the hash returned by Dropbox API.
    #
    # Examples:
    #   {'revision' => 10257, 'rev' => '281100776dce', 'thumb_exists' => false, 'bytes' => 0, 'modified' => 'Wed, 17 Aug 2011 21:04:43 +0000', 'path' => '/1Password.agilekeychain', 'is_dir' => true, 'icon' => 'folder', 'root' => 'dropbox', 'size' => '0 bytes'}
    def initialize(hash)
      @asset_info = OpenStruct.new(DEFAULT_KEYS.merge(hash))
    end

    def to_hash
      %i[revision rev thumb_exists bytes modified path is_dir
         icon root size kind file_extension icon_src name_without_path mime_type].inject({}) do |hash, method|
        hash[method] = public_send method
        hash
      end
    end

    def kind
      is_dir ? 'folder' : 'file'
    end

    def file_extension
      File.extname path.to_s
    end

    def icon_src
      is_dir ? ActionController::Base.helpers.asset_path('dropbox/folder.png') : ActionController::Base.helpers.asset_path('dropbox/file.png')
    end

    def name_without_path
      if back
        '..'
      else
        File.basename(path.to_s).chomp file_extension
      end
    end
  end
end
