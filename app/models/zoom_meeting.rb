# frozen_string_literal: true
class ZoomMeeting < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :session
end
