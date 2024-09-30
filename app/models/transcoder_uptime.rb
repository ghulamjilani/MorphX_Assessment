# frozen_string_literal: true
class TranscoderUptime < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :streamable, polymorphic: true, optional: false

  scope :for_rooms, -> { where(streamable_type: 'Room') }
  scope :for_stream_previews, -> { where(streamable_type: 'StreamPreview') }
end
