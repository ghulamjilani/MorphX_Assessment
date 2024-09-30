# frozen_string_literal: true

module DashboardHelper
  FACEBOOK_CONTACT_MODAL = 'facebook-contact-modal'

  def clone_link(session)
    if session.cloneable_with_options?
      link_to 'Clone', sessions_preview_clone_modal_path(session.id), remote: true
    else
      link_to 'Clone', clone_channel_session_path(session.channel_id, session.id)
    end
  end

  def display_co_present_tab?
    current_user.was_ever_invited_as_co_presenter?
  end

  def display_participate_tab?
    current_user.was_ever_invited_as_participant?
  end

  # TODO: check this. Probably both variants can be used for
  # user that owns channel and/or invited to some channel
  def my_money_dashboard_nav_title
    I18n.t('helpers.dashboard.my_money_dashboard_nav_title')
    # if current_user.has_owned_channels?
    #   'Money'
    # else
    #   'Transactions' # because just "Transaction" for user that only paid in the past could be confusing
    # end
  end

  def sessions_channels_list(sessions)
    sessions.inject({}) do |res, session|
      res[session.channel] ||= []
      res[session.channel] << session
      res
    end
  end

  # Used in dashboard only, so neglect not logged in users here
  def obtain_access_to_session_link(session)
    if session.organizer == current_user
      'Owns'
    elsif can?(:live_opt_out, session) || can?(:vod_opt_out, session)
      I18n.t('shared.immerssed')
    elsif can? :accept_or_reject_invitation, session
      # accept/reject links are displayed in next column
    else
      'Unavailable'
    end
  end

  def status_session_which_could_not_be_obtained(session)
    if session.organizer == current_user
      'Owns'
    elsif can? :opt_out, session
      I18n.t('shared.immerssed')
    else
      'Unavailable'
    end
  end

  def has_active_class(paths, options = {})
    options[:active] = :exclusive
    paths.map { |path| active_link_to_class(path, options) }.find(&:present?)
  end

  def sessions_presents_dashboard_paths
    paths = [sessions_presents_dashboard_path]
    paths << dashboard_path if sessions_presents_dashboard_path == default_dashboard_tab_path
    paths
  end

  def sessions_participates_dashboard_paths
    paths = [sessions_participates_dashboard_path]
    paths << dashboard_path if sessions_participates_dashboard_path == default_dashboard_tab_path
    paths
  end

  def create_btns_visible?
    return false if current_user&.organization.blank?

    %w[sessions_presents].include? @_current_action.to_s
  end

  def dashboard_channel_tabs_paths
    paths = []
    paths << sessions_presents_dashboard_path if current_user&.current_organization&.active_subscription_or_split_revenue?
    paths << sessions_participates_dashboard_path
    paths << sessions_co_presents_dashboard_path if display_co_present_tab?
    paths << dashboard_path
  end

  def default_dashboard_tab_path
    dashboard_channel_tabs_paths.first
  end

  def dashboard_blog_tabs_paths
    [
      spa_dashboard_blog_path,
      spa_dashboard_blog_posts_path,
      new_spa_dashboard_blog_post_path,
      spa_dashboard_blog_comments_path
    ]
  end
end
