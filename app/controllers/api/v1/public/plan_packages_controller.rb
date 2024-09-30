# frozen_string_literal: true

class Api::V1::Public::PlanPackagesController < Api::V1::Public::ApplicationController
  def index
    @plan_packages = PlanPackage.joins(:plans).where(custom: false, active: true, stripe_service_plans: { active: true })
                                .preload(:plans, :feature_parameters).uniq
  end

  def show
    @plan_package = PlanPackage.find(params[:id])
  end
end
