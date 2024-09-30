# frozen_string_literal: true

module Api
  module V1
    module User
      module PageBuilder
        class HomeBannersController < Api::V1::User::PageBuilder::ApplicationController
          before_action :home_banner, only: %i[show destroy]

          def show
          end

          def create
            raise AccessForbiddenError unless current_ability.can?(:create, ::PageBuilder::SystemTemplate)

            @home_banner = ::PageBuilder::HomeBanner.new(params[:image]&.permit(:crop_x, :crop_y, :crop_w, :crop_h, :rotate))
            @home_banner.file = params[:file]
            @home_banner.save
            render :show
          end

          def destroy
            raise AccessForbiddenError unless current_ability.can?(:create, ::PageBuilder::SystemTemplate)

            @home_banner.destroy!
            render :show
          end

          private

          def home_banner
            @home_banner ||= ::PageBuilder::HomeBanner.find(params[:id])
          end

          def current_ability
            @current_ability ||= AbilityLib::PageBuilder::SystemTemplateAbility.new(current_user)
          end
        end
      end
    end
  end
end
