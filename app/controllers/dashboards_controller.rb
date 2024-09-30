# frozen_string_literal: true

class DashboardsController < ApplicationController
  before_action :authenticate_user!
  before_action :extract_action_name
  before_action :set_organization

  def show
    if current_user.current_role == 'presenter' || current_user.has_invited_channels?
      redirect_to sessions_presents_dashboard_url
    elsif current_user.payment_transactions.any? || current_user.channels_subscriptions.any?
      redirect_to spa_dashboard_my_library_index_url
    else
      redirect_to dashboard_history_index_url
    end
  end

  def wishlist
    @wishlist_items = current_user.wishlist_items.order(created_at: :desc)
  end

  def sessions_presents
    if current_user.current_role != 'presenter'
      return redirect_to sessions_participates_dashboard_url
    end

    @channels = []
    if current_user.current_organization&.active_subscription_or_split_revenue?
      @channels = current_user.current_organization.channels.visible_for_user(current_user)
                              .order(title: :asc).preload(:organization).includes([:cover])
    end
    @_current_action = __method__
  end

  def sessions_co_presents
    @abstract_sessions = current_user.co_presenting_or_invited_to_sessions.reorder(start_at: :desc).limit(15)
    @_current_action = __method__

    render :show
  end

  def sessions_participates
    @abstract_sessions = current_user.participating_or_invited_to_sessions.reorder(start_at: :desc).limit(15)
    @_current_action = __method__

    render :show
  end

  def replays
    set_channels
    gon.lists = current_user.current_organization&.lists&.map { |l| { id: l.id, name: l.name } } || ::Shop::List.none
    gon.max_recorded_session_access_cost = SystemParameter.max_recorded_session_access_cost.to_f
  end

  def uploads
    set_channels
    gon.lists = current_user.current_organization&.lists&.map { |l| { id: l.id, name: l.name } } || ::Shop::List.none
    gon.max_recorded_session_access_cost = SystemParameter.max_recorded_session_access_cost.to_f
  end

  def video_on_demand_link # NOTE: for now it only for session type, because not all clear
    session = Session.where(presenter_id: current_user.presenter.try(:id)).find_by(id: params[:session_id])

    session ||= begin
      recorded_member = RecordedMember.where(participant: current_user.participant)
                                      .where(abstract_session_type: 'Session').find_by!(abstract_session_id: params[:session_id])

      recorded_member.increment!(:video_views_count)
      recorded_member.abstract_session
    end

    video = Video.where(room_id: session.room_id).find(params[:video_id])

    redirect_to video.url
  end

  def edit_referral
    @referral_users = current_user.my_referral_users
    @referral_code = current_user.my_referral_code_text
  end

  def followers
    @followers = current_user.user_followers.includes(:image, :user_account)
  end

  def following
    @followings = current_user.following_users.includes(:image, :user_account)
  end

  def company
    @company = current_user.organization
    @invited_companies = current_user.organizations
  end

  # def business_plan
  #   @subscriptions = current_user.service_subscriptions.
  #     page(params[:page]).per(@per_page)
  # end

  private

  def extract_action_name
    @action_name = action_name
  end

  # channels
  def presenting
  end

  def owned
  end

  def invited
  end

  def participated
  end

  def set_organization
    @current_organization = @organization = current_user.current_organization
  end

  def set_channels
    @channels = []
    if current_user&.current_organization&.active_subscription_or_split_revenue?
      @channels = current_user.current_organization.channels.approved.not_archived.order(created_at: :desc)
    end
    gon.channels = @channels.map do |channel|
      {
        id: channel.id,
        title: channel.title,
        absolute_path: channel.absolute_path,
        logo_url: (channel.logo || channel.main_image.persisted?) ? channel.logo_url : channel.image_gallery_url,
        created_at: channel.created_at.strftime('%m.%d.%Y')
      }
    end
  end
end
