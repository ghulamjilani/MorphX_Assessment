# frozen_string_literal: true

module WizardHelper
  def channel_link
    current_user&.user_info_ready? ? wizard_v2_channel_path : '#'
  end

  def settings_link
    (current_user&.user_info_ready? && current_user&.channel_ready?) ? wizard_v2_summary_path : ''
  end
end
