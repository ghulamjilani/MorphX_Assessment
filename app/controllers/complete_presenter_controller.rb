# frozen_string_literal: true

class CompletePresenterController < ApplicationController
  before_action :authenticate_user!

  def index
    return redirect_to root_path if params[:channel_id].blank?

    channel = Channel.find(params[:channel_id])
    @channel_name = Channel.find(params[:channel_id]).title
    @network_name = channel.organization ? channel.organization.name : channel.organizer.display_name
    current_user.build_user_account unless current_user.user_account
    # SocialLink::Providers::ORDERED_ALL.each do |provider|
    #   unless current_user.user_account.social_links.exists?(provider: provider)
    #     current_user.user_account.social_links.build(entity: current_user.user_account, provider: provider)
    #   end
    # end
    gon.channel_id = params[:channel_id]
    gon.channel_path = channel.relative_path
    gon.user = user_json(current_user)
    gon.user_info_ready = current_user.user_info_ready?
  end

  def save
    @interactor = BecomePresenter::SaveUserAccountInfo.new(current_user, user_account_attributes)
    if @interactor.execute
      channel = Channel.find(params[:channel_id])
      render json: { path: channel.relative_path }
    else
      errors = @interactor.errors
      render json: errors, status: 422
    end
  end

  private

  # json data
  def user_json(user)
    json = user.as_json.slice('id', 'first_name', 'last_name', 'email', 'gender', 'manually_set_timezone', 'slug')
    if user.user_account
      json.merge!(user.user_account.as_json.slice('country', 'tagline', 'bio', 'available_by_request_for_live_vod',
                                                  'bg_image_url', 'talent_list'))
      json[:phone] =
        user.user_account.phone.present? ? user.user_account.phone.phony_formatted(format: :international) : ''
      json[:confirmed_phone_numbers] = user.authy_records.where(status: AuthyRecord::Statuses::APPROVED).collect do |ar|
        "+#{ar.country_code}#{ar.cellphone}"
      end
      json[:cover] = user.user_account.bg_image_url
    end
    json[:logo] = user.medium_avatar_url
    if user.birthdate
      json[:birthdate_d] = user.birthdate.day
      json[:birthdate_m] = user.birthdate.month
      json[:birthdate_y] = user.birthdate.year
    end
    json[:current_user] = (current_user == user)
    json[:presenter_id] = user.presenter_id
    json
  end

  def user_account_attributes
    if params[:user_account].present?
      params.require(:user_account).permit(
        :bio,
        :available_by_request_for_live_vod,
        logo: %i[crop_x crop_y crop_w crop_h rotate original_image]
        # social_links_attributes: [:link, :provider, :id]
      )
    end
  end
end
