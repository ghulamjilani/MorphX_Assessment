# frozen_string_literal: true

module Api
  module V1
    module Public
      class InteractiveAccessTokensController < Api::V1::Public::ApplicationController
        def show
          @interactive_access_token = InteractiveAccessToken.find_by!(token: params[:id])
        end
      end
    end
  end
end
