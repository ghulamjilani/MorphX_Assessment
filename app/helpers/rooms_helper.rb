# frozen_string_literal: true

module RoomsHelper
  def show_vidyo_credentials?(room:, role:)
    return false unless %(presenter co_presenter participant).include?(role)
    return false unless room.service_type == 'vidyo'
    return true if role == 'presenter'
    return true if room.active?
  end
end
