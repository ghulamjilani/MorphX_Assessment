# frozen_string_literal: true

module Api
  module V1
    module User
      module Storage
        class RecordsController < Api::V1::User::Storage::ApplicationController
          def index
            raise AccessForbiddenError unless can?(:view_statistics, current_user.current_organization)

            query = ::Storage::Record.where(organization: current_user.current_organization)
            query = query.where(model_type: params[:model_type]) if params[:model_type].present?
            query = query.where(model_id: params[:model_id]) if params[:model_id].present?
            query = query.where(relation_type: params[:relation_type]) if params[:relation_type].present?
            query = query.where(object_type: params[:object_type]) if params[:object_type].present?

            order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
            @count = query.count
            @records = query.order(Arel.sql("updated_at #{order}")).limit(@limit).offset(@offset)
          end

          private

          def current_ability
            AbilityLib::OrganizationAbility.new(current_user)
          end
        end
      end
    end
  end
end
