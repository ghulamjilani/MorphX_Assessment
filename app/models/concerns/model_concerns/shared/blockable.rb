# frozen_string_literal: true

module ModelConcerns
  module Shared
    module Blockable
      extend ActiveSupport::Concern

      included do
        validates :block_reason, presence: { if: :blocked? }
        scope :blocked, -> { where(blocked: true) }
        after_commit :send_block_notification, if: ->(model) { model.saved_change_to_blocked? && model.blocked? }

        private

        def send_block_notification
          BlockableMailer.content_blocked(self.class.name, id).deliver_later
        end
      end
    end
  end
end
