# frozen_string_literal: true

module ModelConcerns
  module Shared
    module Transcodable
      extend ActiveSupport::Concern

      included do
        has_many :transcode_tasks, as: :transcodable, dependent: :delete_all
        has_one :transcode_task, -> { order(created_at: :desc) }, inverse_of: :transcodable, foreign_key: 'transcodable_id', dependent: nil

        def transcode_task_percent
          transcode_task&.percent.to_i
        end
      end
    end
  end
end
