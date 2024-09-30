# frozen_string_literal: true

class Api::V1::Public::UsersController < Api::V1::Public::ApplicationController
  before_action :set_user, only: %i[show creator_info]

  def show
    @user.log_daily_activity(:view, owner: current_user) if current_user.present?
  end

  def creator_info
    @user.log_daily_activity(:view, owner: current_user) if current_user.present? && params[:log_activity] != '0'
    @following = (current_user.present? && current_user.following?(@user))
    @owned_channels = if @user.organization&.active_subscription_or_split_revenue?
                        @user.owned_channels.approved.listed.not_fake.not_archived
                             .preload(:cover, :logo, :category, :taggings, :channel_links, :images)
                      else
                        []
                      end

    @invited_channels = @user.invited_channels.approved.listed.not_fake.not_archived
                             .preload(:cover, :logo, :category, :taggings, :channel_links, :images)
    @bio = @user.user_account&.bio
    @social_links = @user.user_account&.social_links
  end

  def fetch_avatar
    @url = if (user = User.where(%(lower(users.email) = lower(?)), params[:email]).first)
             user.medium_avatar_url
           else
             ''
           end
  end

  private

  def set_user
    @user = User.friendly.find(params[:id])
  end
end
