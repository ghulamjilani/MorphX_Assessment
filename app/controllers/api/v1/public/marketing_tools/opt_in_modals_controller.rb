# frozen_string_literal: true

module Api
  module V1
    module Public
      module MarketingTools
        class OptInModalsController < Api::V1::Public::MarketingTools::ApplicationController
          def index
            query = ::MarketingTools::OptInModal.joins(:channel).where(active: true)

            if params[:model_type].present? && params[:model_id].present?
              query = query.for_model(params[:model_type], params[:model_id])
            else
              raise I18n.t('controllers.api.v1.public.marketing_tools.opt_in_modals.errors.model_params_required')
            end

            @count = query.count

            order_by = if %w[title created_at].include?(params[:order_by])
                         params[:order_by]
                       else
                         'title'
                       end
            order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
            @modals = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
          end

          def track_view
            modal = ::MarketingTools::OptInModal.where(active: true).find(params[:id])
            modal.increment!(:views_count)
            head 200
          end
        end
      end
    end
  end
end
