# frozen_string_literal: true

class Spa::Reports::NetworkSalesReportsController < Spa::ApplicationController
  def index
    @organization = current_user&.current_organization
  end
end
