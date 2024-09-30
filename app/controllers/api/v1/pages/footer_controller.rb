# frozen_string_literal: true

class Api::V1::Pages::FooterController < Api::V1::ApplicationController
  skip_before_action :authorization
  def show
  end
end
