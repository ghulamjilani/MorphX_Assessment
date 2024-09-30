# frozen_string_literal: true

module ControllerConcerns::SessionFormParams
  extend ActiveSupport::Concern

  private

  def session_params
    params.require(:session).permit(
      :adult,
      :age_restrictions,
      :allow_chat,
      :autostart,
      :channel_id,
      :custom_description_field_label,
      :custom_description_field_value,
      :description,
      :device_type,
      :duration,
      :free_trial_for_first_time_participants,
      :immersive_access_cost,
      :immersive_free_slots,
      :immersive_free_trial,
      :immersive_free,
      :immersive_type,
      :immersive,
      :level,
      :livestream_access_cost,
      :livestream_free_slots,
      :livestream_free_trial,
      :livestream_free,
      :livestream,
      :max_number_of_immersive_participants,
      :min_number_of_immersive_and_livestream_participants,
      :only_ppv,
      :only_subscription,
      :pre_time,
      :presenter_id,
      :private,
      :publish_after_requested_free_session_is_satisfied_by_admin,
      :record,
      :recorded_access_cost,
      :recorded_free,
      :recording_layout,
      :requested_free_session_reason,
      :service_type,
      :start_at,
      :start_now,
      :title,
      :twitter_feed_title,
      :ffmpegservice_account_id,
      :crop_x, :crop_y, :crop_w, :crop_h, :rotate, :cover,
      recurring_settings: [:active, :until, :date, :occurrence, { days: [] }],
      session_sources_attributes: %i[id name _destroy],
      dropbox_materials_attributes: %i[id path _destroy mime_type]
    ).tap do |result|
      # attr_writes
      # so that in validators you can distinguish these flags set from controller and other updates
      # NOTE: raw value is '1' or nil so !! does the trick
      result['allow_chat'] = %w[true 1 on].include?(result['allow_chat']) || result['allow_chat'] == true
      result['only_subscription'] =
        %w[true 1 on].include?(result['only_subscription']) || result['only_subscription'] == true
      result['only_ppv'] = %w[true 1 on].include?(result['only_ppv']) || result['only_ppv'] == true
      if result.has_key?('immersive')
        result['immersive'] = %w[true 1 on].include?(result['immersive']) || result['immersive'] == true
      end
      if result.has_key?('livestream')
        result['livestream'] = %w[true 1 on].include?(result['livestream']) || result['livestream'] == true
      end
      if result.has_key?('record')
        result['record'] = %w[true 1 on].include?(result['record']) || result['record'] == true
      end
      result['adult'] = !!result['adult']

      unless result['immersive']
        result['immersive_free'] = false
        result['immersive_type'] = nil
        result['immersive_access_cost'] = nil
        result['max_number_of_immersive_participants'] = 0
      end
      unless result['livestream']
        result['livestream_free'] = false
        result['livestream_access_cost'] = nil
      end
      unless result['record']
        result['recorded_free'] = false
        result['recorded_access_cost'] = nil
      end
      if params[:session][:custom_start_at]
        date = DateTime.parse(params[:session][:custom_start_at])
        result['start_at(4i)'] = date.hour.to_s
        result['start_at(5i)'] = date.minute.to_s
      end
      result['publish_after_requested_free_session_is_satisfied_by_admin'] =
        (result['publish_after_requested_free_session_is_satisfied_by_admin'] == '1' if result['livestream_free'] || result['immersive_free'] || result['recorded_free'])
    end
  end

  def poll_params
    return {} if params[:session][:poll].blank?

    # remove blank answers
    attrs = {}
    params[:session][:poll][:sides].to_a.delete_if { |s| s[:answer].blank? }
    if params[:session][:poll][:question].present? && params[:session][:poll][:sides].to_a.size > 1
      attrs['sides'] = params[:session][:poll][:sides]
      attrs['question'] = attrs['tagline'] = params[:session][:poll][:question]
      attrs['imageUrl'] = params[:session][:poll][:image_url] if params[:session][:poll][:image_url].present?
      attrs['categoryId'] = params[:session][:poll][:category_id] || 1 # default technology
      attrs['timeBased'] = false
      attrs['privatePoll'] = true
    end
    attrs
  end
end
