# frozen_string_literal: true

class Api::V1::Public::ServicePlansController < Api::V1::Public::ApplicationController
  def show
    @plan = StripeDb::ServicePlan.find(params[:id])
  end
end
