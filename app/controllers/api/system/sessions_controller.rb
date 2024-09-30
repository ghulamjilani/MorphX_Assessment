# frozen_string_literal: true

class Api::System::SessionsController < Api::System::ApplicationController
  before_action :http_basic_authenticate
  before_action :load_session, only: [:update_pg_search_document]

  def update_pg_search_document
    @session.update_pg_search_document
    head :ok
  end

  private

  def load_session
    @session = Session.find params[:id]
  end
end
