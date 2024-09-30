# frozen_string_literal: true

module HomeHelper
  def display_almost_done_modal?
    return false if params[:autodisplay_remote_ujs_path].present?
    return false unless user_signed_in?

    # if all fields are filled, just return false
    return false if current_user.user_info_ready?

    # display this modal daily untill it is finally filled
    cache_key = "#{__method__}/#{current_user.id}/#{Time.now.strftime('%d.%m.%y')}"

    checked_for_first_time_today = Rails.cache.read(cache_key).nil?
    if checked_for_first_time_today
      Rails.cache.write(cache_key, 'already checked today')
      true
    else
      false
    end
  end

  def wishlist_class(model)
    'active' if user_signed_in? && current_user.has_in_wishlist?(model)
  end

  def wishlist_caption(session)
    unless user_signed_in?
      return I18n.t('sessions.show.wishlist.add_caption')
    end

    current_user.has_in_wishlist?(session) ? I18n.t('sessions.show.wishlist.added_caption') : I18n.t('sessions.show.wishlist.add_caption')
  end

  def like_class(model)
    return '' unless user_signed_in?

    'selected active' if current_user.voted_as_when_voted_for(model)
  end

  def view_class(session)
    return '' unless user_signed_in?

    'selected' if current_user.saw?(session)
  end

  def participant_class(session)
    return '' unless user_signed_in?

    'selected' if session.has_immersive_participant?(current_user.participant_id)
  end
end
