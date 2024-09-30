# frozen_string_literal: true

class ReindexJob < ApplicationJob
  def perform(entities = [])
    possible_entities = %w[User Channel Session Video Recording Blog::Post]
    entities = entities.split(',') if entities.is_a? String
    entities.reject! { |entity| possible_entities.exclude?(entity.to_s) }
    entities = possible_entities if entities.blank?
    entities.each do |entity|
      entity.strip.constantize.multisearch_reindex
    end
  end
end
