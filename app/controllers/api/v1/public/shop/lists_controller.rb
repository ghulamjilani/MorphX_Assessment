# frozen_string_literal: true

module Api
  module V1
    module Public
      module Shop
        class ListsController < Api::V1::Public::ApplicationController
          before_action :set_list, only: [:show]

          def index
            if ::Shop::AttachedList::MODEL_TYPES.include?(params[:model_type]) && params[:model_id].present?
              query = ::Shop::List.joins(:attached_lists).where(attached_lists: { model_type: params[:model_type], model_id: params[:model_id] })
            else
              return render_json 422, 'Parameters model_id & model_type should be provided'
            end
            @count = query.count
            order_by = %w[created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
            order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
            @lists = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset).preload(:products)
          end

          def show
          end

          private

          def set_list
            @list = ::Shop::List.find(params[:id])
          end
        end
      end
    end
  end
end
