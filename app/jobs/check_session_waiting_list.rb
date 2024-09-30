# frozen_string_literal: true

class CheckSessionWaitingList < ApplicationJob
  def perform(session_id)
    # find all changes by TEMPORARYDISABLE
    # session = Session.find(session_id)

    # session.session_waiting_list.users.each do |user|
    #   SessionMailer.hurry_up_to_purchase_slot(session.id, user.id).deliver_now
    # end
  end
end
