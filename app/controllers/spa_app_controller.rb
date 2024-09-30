# frozen_string_literal: true

class SpaAppController < ActionController::Base
  include ControllerConcerns::GoService
  layout 'spa_application'

  def index
  end
end
