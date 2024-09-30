# frozen_string_literal: true

class CheckSessionNoReservation < ApplicationJob
  def perform(session_id)
    # temporary restore this job to avoid fails
  end
end
