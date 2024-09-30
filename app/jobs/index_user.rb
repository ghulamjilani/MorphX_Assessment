# frozen_string_literal: true

class IndexUser < ApplicationJob
  def perform(user_id)
    user = User.find_by(id: user_id)
    user&.update_pg_search_document
  end
end
