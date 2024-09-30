# frozen_string_literal: true

module Api
  module V1
    module User
      class AbstractSessionCancelReasonsController < Api::V1::User::ApplicationController
        def index
          @session_cancel_reasons = AbstractSessionCancelReason.order(name: :asc).limit(@limit).offset(@offset)
          @count = AbstractSessionCancelReason.count
        end
      end
    end
  end
end
