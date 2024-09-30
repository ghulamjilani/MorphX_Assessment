# frozen_string_literal: true

module ModelConcerns
  module User
    module ActsAsVoter
      extend ActiveSupport::Concern

      included do
        acts_as_voter

        def liked?(model)
          Rails.cache.fetch(voted_model_cache_key(model)) do
            lambda do
              voted_up_on?(model)
            end.call
          end
        end

        def like(model)
          vote_up_for(model) && Rails.cache.write(voted_model_cache_key(model), true)
        end

        def unlike(model)
          unvote_for(model) && Rails.cache.write(voted_model_cache_key(model), false)
        end

        def clear_liked_cache(model)
          Rails.cache.delete(voted_model_cache_key(model))
        end

        def voted_model_cache_key(model)
          "user/#{id}/has_liked/#{model.class.name}/#{model.id}"
        end
      end
    end
  end
end
