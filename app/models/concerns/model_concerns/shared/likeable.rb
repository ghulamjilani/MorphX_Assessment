# frozen_string_literal: true

module ModelConcerns
  module Shared
    module Likeable
      extend ActiveSupport::Concern

      included do
        def likes_count(skip_cache: false)
          count_votes_up(skip_cache).to_i
        end
      end
    end
  end
end
