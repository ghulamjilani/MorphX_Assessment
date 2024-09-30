# frozen_string_literal: true

# "customize the layout of your error handling using controllers and views"
# NOTE: I'm following official Rails documentation/recommendation here

class ErrorsController < ActionController::Base
  layout 'error'

  def not_found
    respond_to do |format|
      format.html { render 'errors/not_found', status: 404 }
    end
  end

  def unprocessable_entity
    respond_to do |format|
      format.html { render 'errors/unprocessable_entity', status: 404 }
    end
  end

  def server_error
    respond_to do |format|
      format.html { render 'errors/server_error', status: 404 }
    end
  end
end
