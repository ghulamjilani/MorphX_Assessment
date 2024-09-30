# frozen_string_literal: true

module Api
  module V1
    module Public
      module Poll
        class PollsController < Api::V1::Public::ApplicationController
          def show
            @poll = ::Poll::Poll.find(params[:id])
          end
        end
      end
    end
  end
end
