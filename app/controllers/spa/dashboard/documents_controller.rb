# frozen_string_literal: true

module Spa
  module Dashboard
    class DocumentsController < Spa::Dashboard::ApplicationController
      def index
        if current_ability.can?(:manage_documents, @organization)
          render html: '', layout: 'spa_application'
        else
          redirect_to dashboard_path, flash: { error: 'Access denied' }
        end
      end
    end
  end
end
