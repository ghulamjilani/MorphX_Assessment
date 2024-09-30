# frozen_string_literal: true

module ModelConcerns
  module Shared
    module Blog
      module HasMentions
        extend ActiveSupport::Concern

        def mentioned_user_ids
          Html::Parser.new(body).mentioned_user_ids
        end
      end
    end
  end
end
