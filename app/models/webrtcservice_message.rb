# frozen_string_literal: true
class WebrtcserviceMessage < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :user
end
