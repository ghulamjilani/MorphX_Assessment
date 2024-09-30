# frozen_string_literal: true

module Api
  module V1
    module Public
      module Shop
        class ProductsController < Api::V1::Public::ApplicationController
          def index
            if params[:list_id].present?
              query = ::Shop::Product
              @list = ::Shop::List.find(params[:list_id])
            else
              return render_json 422, 'Parameter list_id should be provided'
            end

            query = query.joins(:lists).where(lists: { id: @list.id })
            order_by = %w[id created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
            order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
            @count = query.count
            @products = query.order("#{order_by} #{order}").limit(@limit).offset(@offset)
          end

          def show
            @product = ::Shop::Product.find(params[:id])
          end
        end
      end
    end
  end
end
