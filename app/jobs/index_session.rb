# frozen_string_literal: true

class IndexSession < ApplicationJob
  def perform(session_id)
    session = Session.find(session_id)
    session&.update_pg_search_document
  end
end
