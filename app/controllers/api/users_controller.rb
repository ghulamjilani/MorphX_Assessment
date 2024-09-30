# frozen_string_literal: true

class Api::UsersController < Api::ApplicationController
  # curl -XGET http://localhost:3000/api_portal/users/1.json -H 'X-User-Token: 9f3f5ab404dde17472119127b52aeadb1' -H 'X-User-ID:1'
  def show
    @user = User.find(params[:id])
    social_links = @user.account&.social_links || []
    @facebook_social_link  = social_links.detect { |sl| sl.provider == SocialLink::Providers::FACEBOOK }
    @twitter_social_link   = social_links.detect { |sl| sl.provider == SocialLink::Providers::TWITTER }
    @gplus_social_link     = social_links.detect { |sl| sl.provider == SocialLink::Providers::GPLUS }
    @linkedin_social_link  = social_links.detect { |sl| sl.provider == SocialLink::Providers::LINKEDIN }
    @youtube_social_link   = social_links.detect { |sl| sl.provider == SocialLink::Providers::YOUTUBE }
    @instagram_social_link = social_links.detect { |sl| sl.provider == SocialLink::Providers::INSTAGRAM }
    @telegram_social_link  = social_links.detect { |sl| sl.provider == SocialLink::Providers::TELEGRAM }

    @website_url = social_links.detect { |sl| sl.provider == SocialLink::Providers::EXPLICIT }
    @owned_channels = @user.all_channels.approved.listed.not_fake.not_archived.order(is_default: :desc)
  rescue StandardError => e
    render_json(500, e.message, e)
  end

  def toggle_follow
    @user = User.where(id: params[:id], deleted: [false, nil]).last!
    authorize!(:follow, @user)

    @following = current_user.toggle_follow(@user)
    @count = @user.count_user_followers

    render json: { subscribed: @following, count: @count }
  rescue StandardError => e
    render_json(500, e.message, e)
  end
end
