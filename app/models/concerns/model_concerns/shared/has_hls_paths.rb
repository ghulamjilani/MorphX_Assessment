# frozen_string_literal: true

module ModelConcerns
  module Shared
    module HasHlsPaths
      extend ActiveSupport::Concern

      included do
        def hls_main_path
          return nil unless respond_to?(:hls_main)
          return nil if hls_main.blank?

          hls_main.gsub('playlist.m3u8', '')
        end

        def hls_preview_path
          return nil unless respond_to?(:hls_preview)
          return nil if hls_preview.blank?

          hls_preview.gsub('playlist.m3u8', '')
        end
      end
    end
  end
end
