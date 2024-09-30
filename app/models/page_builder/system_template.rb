# frozen_string_literal: true
module PageBuilder
  class SystemTemplate < PageBuilder::ApplicationRecord
    class << self
      def template_cache_key(name)
        "PageBuilder::SystemTemplate/#{name}/"
      end
    end

    has_one :opt_in_modal, class_name: 'MarketingTools::OptInModal', inverse_of: :system_template, foreign_key: :pb_system_template_id, primary_key: :id, dependent: :destroy
    validates :name, presence: true, uniqueness: true

    def template_cache_key
      SystemTemplate.template_cache_key(name)
    end
  end
end
