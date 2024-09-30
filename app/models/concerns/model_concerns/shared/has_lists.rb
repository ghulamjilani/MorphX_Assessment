# frozen_string_literal: true

module ModelConcerns
  module Shared
    module HasLists
      extend ActiveSupport::Concern

      included do
        has_many :attached_lists, class_name: 'Shop::AttachedList', as: :model, dependent: :destroy
        has_many :lists, class_name: 'Shop::List', through: :attached_lists

        accepts_nested_attributes_for :attached_lists, reject_if: ->(a) { a[:list_id].blank? }, allow_destroy: true
      end
    end
  end
end
