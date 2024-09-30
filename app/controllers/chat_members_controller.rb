# frozen_string_literal: true

class ChatMembersController < ApplicationController
  include ControllerConcerns::ValidatesRecaptcha

  skip_before_action :gon_init
  skip_before_action :check_if_has_needed_cookie
  skip_before_action :extract_refc_from_url_into_cookie
  skip_before_action :check_if_referral_user
  skip_after_action :prepare_unobtrusive_flash
  skip_before_action :fetch_latest_notifications
  skip_before_action :fetch_upcoming_sessions_for_user
  skip_before_action :store_current_location

  def create
    unless recaptcha_verified?
      render(json: { message: Recaptcha::Helpers.to_error_message(:verification_failed) }, status: 422) and return
    end

    chat_channel = ChatChannel.find_by(webrtcservice_id: params[:webrtcservice_channel_id])
    session = Session.find_by(id: chat_channel.session_id)
    chat_ban = ChatBan.where(channel_id: session.channel_id, ip_address: request.remote_ip,
                             user_agent: request.user_agent).count.positive?
    if chat_ban
      return render json: { message: "You're banned" }, status: 401
    end

    member = ChatMember.new(params.require(:chat_member).permit(:name, :location))
    member.ip_address = request.remote_ip
    member.user_agent = request.user_agent
    member.save!
    member_json = {
      id: member.id.to_s,
      type: 'ChatMember',
      public_display_name: [member.name, member.location.presence].compact.join(' from '),
      avatar_url: view_context.image_url('gender/newMale.svg')
    }
    render json: { member: member_json }, status: 200
  end
end
