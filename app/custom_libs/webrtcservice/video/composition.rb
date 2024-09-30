# frozen_string_literal: true

module Webrtcservice
  module Video
    class Composition
      module Layouts
        PRESENTER_ONLY = 'presenter_only'
        PRESENTER_FOCUS = 'presenter_focus'
        GRID = 'grid'

        ALL = [PRESENTER_ONLY, PRESENTER_FOCUS, GRID].freeze
      end

      class << self
        def layout_parameters(layout:, presenter_sids: [], user_sids: [])
          case layout
          when Layouts::PRESENTER_ONLY
            parameters_presenter_only(presenter_sids:, user_sids:)
          when Layouts::PRESENTER_FOCUS
            parameters_presenter_focus(presenter_sids:, user_sids:)
          when Layouts::GRID
            parameters_grid
          else
            raise "unknown composition layout '#{layout}'"
          end
        end

        def parameters_presenter_only(presenter_sids:, user_sids:)
          {
            AudioSources: presenter_sids,
            VideoLayout: {
              main: {
                z_pos: 0,
                max_columns: 1,
                max_rows: 1,
                reuse: 'show_newest',
                video_sources: presenter_sids,
                video_sources_excluded: ['share']
              },
              share: {
                z_pos: 1,
                video_sources: ['share'],
                video_sources_excluded: user_sids
              }
            }.to_json
          }
        end

        def parameters_presenter_focus(presenter_sids:, user_sids:)
          {
            AudioSources: '*',
            VideoLayout: {
              main: {
                z_pos: 0,
                max_columns: 1,
                max_rows: 1,
                reuse: 'show_newest',
                video_sources: presenter_sids,
                video_sources_excluded: ['share']
              },
              share: {
                z_pos: 1,
                video_sources: ['share'],
                video_sources_excluded: user_sids
              }
            }.to_json
          }
        end

        def parameters_grid
          {
            AudioSources: '*',
            VideoLayout: {
              grid: {
                z_pos: 0,
                video_sources: ['*'],
                video_sources_excluded: ['share'],
                max_columns: 7,
                max_rows: 5,
                reuse: 'show_newest'
              },
              share: {
                z_pos: 1,
                video_sources: ['share']
              }
            }.to_json
          }
        end
      end
    end
  end
end
