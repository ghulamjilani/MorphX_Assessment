# frozen_string_literal: true

module SystemParametersHelper
  def stub_system_parameters
    allow(SystemParameter).to receive(:full_money_or_credit_not_sooner_than_hours).and_return(12)
    allow(SystemParameter).to receive(:half_credit_not_sooner_than_hours).and_return(4)

    allow(SystemParameter).to receive(:max_number_of_immersive_participants).and_return(99)

    allow(SystemParameter).to receive(:max_one_on_one_immersive_session_access_cost).and_return(100.99)
    allow(SystemParameter).to receive(:max_group_immersive_session_access_cost).and_return(100.99)
    allow(SystemParameter).to receive(:max_livestream_session_access_cost).and_return(100.99)
    allow(SystemParameter).to receive(:max_recorded_session_access_cost).and_return(100.99)

    allow(SystemParameter).to receive(:book_ahead_in_hours_max).and_return(7872)
    allow(SystemParameter).to receive(:check_slots_hours_before_start).and_return(48)

    allow(SystemParameter).to receive(:channel_images_max_count).and_return(15)
    allow(SystemParameter).to receive(:channel_links_max_count).and_return(15)

    allow(SystemParameter).to receive(:co_presenter_fee).and_return(5)

    allow(SystemParameter).to receive(:max_number_of_livestream_free_trial_slots).and_return(25)

    allow(SystemParameter).to receive(:min_session_cancellation_fee_per_paid_immersive_participant).and_return(1)
    allow(SystemParameter).to receive(:min_session_cancellation_fee_per_paid_livestream_participant).and_return(1)

    allow(SystemParameter).to receive(:max_session_cancellation_fee_per_paid_immersive_participant).and_return(9)
    allow(SystemParameter).to receive(:max_session_cancellation_fee_per_paid_livestream_participant).and_return(9)

    allow(SystemParameter).to receive(:referral_participant_fee_in_percent).and_return(5.0)
  end
end
