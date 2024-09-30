# frozen_string_literal: true

module Api
  module V1
    module User
      module Payouts
        class MerchantCategoriesController < Api::V1::User::ApplicationController
          def index
            @merchant_categories = MerchantCategory.all.order(name: :asc)
          end
        end
      end
    end
  end
end
