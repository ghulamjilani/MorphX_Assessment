# frozen_string_literal: true

module Api
  module V1
    module Public
      module MarketingTools
        class OptInModalSubmitsController < Api::V1::Public::MarketingTools::ApplicationController
          def create
            modal = ::MarketingTools::OptInModal.where(active: true).find(params[:opt_in_modal_id])
            modal.opt_in_modal_submits.create!(data: params[:data],
                                               mrk_tools_opt_in_modal_id: params[:opt_in_modal_id],
                                               user_uuid: current_user&.uuid)

            head 200
          end
        end
      end
    end
  end
end
