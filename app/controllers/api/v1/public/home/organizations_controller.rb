# frozen_string_literal: true

module Api
  module V1
    module Public
      module Home
        class OrganizationsController < Api::V1::Public::Home::ApplicationController
          def index
            query = ::Organization.not_fake.for_home_page
            @count = query.count
            order_by = if %w[created_at views_count].include?(params[:order_by])
                         params[:order_by]
                       else
                         'views_count'
                       end

            promo_order = params[:promo_weight].blank? ? '' : 'CASE WHEN ((organizations.promo_weight <> 0 AND organizations.promo_start IS NULL AND organizations.promo_end IS NULL) OR (organizations.promo_start < now() AND now() < organizations.promo_end)) THEN 100 + organizations.promo_weight ELSE 0 END DESC, '
            order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
            @organizations = query.order(Arel.sql("#{promo_order}#{order_by} #{order}")).limit(@limit).offset(@offset).preload(:logo, :user, :company_setting, :cover, user: :image)
          end
        end
      end
    end
  end
end
