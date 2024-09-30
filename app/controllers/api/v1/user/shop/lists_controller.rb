# frozen_string_literal: true

module Api
  module V1
    module User
      module Shop
        class ListsController < Api::V1::User::ApplicationController
          before_action :check_credentials, except: %i[index show]
          before_action :set_list, except: %i[index create]

          def index
            query = current_user.current_organization.lists
            if ::Shop::AttachedList::MODEL_TYPES.include?(params[:model_type]) && params[:model_id].present?
              query = query.joins(:attached_lists).where(attached_lists: { model_type: params[:model_type], model_id: params[:model_id] })
            end
            @count = query.count
            order_by = %w[created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
            order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
            @lists = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset).preload(:products)
          end

          def show
          end

          def create
            @list = current_user.current_organization.lists.create!(list_params)
            render :show
          end

          def update
            @list.update(list_params)
            render :show
          end

          def destroy
            return render_json(422, @list) unless @list.destroy

            head 200
          end

          private

          def check_credentials
            authorize!(:manage_product, current_user.current_organization)
          end

          def set_list
            @list = current_user.current_organization.lists.find(params[:id])
          end

          def list_params
            params.permit(:name, :description)
          end
        end
      end
    end
  end
end
