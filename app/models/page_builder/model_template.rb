# frozen_string_literal: true
module PageBuilder
  class ModelTemplate < PageBuilder::ApplicationRecord
    class << self
      def template_cache_key(type:, id:)
        "PageBuilder::ModelTemplate/#{type}/#{id}/"
      end
    end

    belongs_to :model, polymorphic: true, optional: false
    belongs_to :organization

    before_validation :assign_organization

    validates :model_type, inclusion: { in: %w[User Organization Channel] }

    def template_cache_key
      ModelTemplate.template_cache_key(type: model_type, id: model_id)
    end

    private

    def assign_organization
      self.organization = case model.class.name
                          when 'Channel'
                            model.organization
                          when 'Organization'
                            model
                          end
    end
  end
end
