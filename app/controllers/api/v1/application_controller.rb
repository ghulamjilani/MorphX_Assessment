# frozen_string_literal: true

# Video E-Commerce for Enterprises
class Api::V1::ApplicationController < ActionController::Base
  include ControllerConcerns::Api::V1::Authorization
  include ControllerConcerns::Api::V1::HasJwtAuth
  include ControllerConcerns::Api::V1::SharedControllerHelper
  include Pundit::Authorization

  before_action :authorization
  before_action :offset_limit, only: [:index]
  skip_before_action :verify_authenticity_token

  rescue_from Exception do |e|
    case e.class.to_s
    when 'NotAuthorizedError'
      render_json(401, e.message, e)
    when 'Pundit::NotAuthorizedError', 'CanCan::AccessDenied', 'AccessForbiddenError'
      render_json(403, e.message, e)
    when 'ActiveRecord::RecordNotFound'
      render_json(404, e.message, e)
    when 'Mongoid::Errors::DocumentNotFound'
      render_json(404, e.problem, e)
    when 'ActiveRecord::RecordInvalid', 'ArgumentError', 'ActionController::ParameterMissing'
      render_json(422, e.message, e)
    else
      render_json(500, e.message, e)
    end
  end

  respond_to :json

  def envelope(json, status = 'OK', message = nil, errors = nil)
    json.status status
    json.message message if message
    json.time_now Time.now.utc.to_fs(:rfc3339)

    errors = message if errors.nil? && (400..500).cover?(status)

    if errors.blank?
      json.errors({})
    elsif errors.is_a?(String)
      json.errors do
        json.message errors
      end
    elsif errors.is_a?(ActiveModel::Errors) || errors.is_a?(Hash)
      json.errors do
        errors.each do |k, value|
          json.set! k.to_sym, (value.is_a?(Array) ? value.join('; ') : value)
        end
      end
    end

    if block_given?
      json.response do
        yield
      end
    end

    json.pagination do
      if @offset && @limit && @count
        @current_page = (@offset + @limit) / @limit

        json.count @count
        json.limit @limit
        json.offset @offset
        json.total_pages (@count + @limit - 1) / @limit
        json.current_page @current_page
      end
    end

    json.current_user_id current_user.id if current_user
    json.current_guest_id current_guest.id if current_guest
  end
  helper_method :envelope

  # render_json 200
  # render_json 401
  # render_json 404
  # render_json 500, e.message, e
  def render_json(status, text = nil, error = nil)
    notify_airbrake(error || text) if status == 500
    puts error.message    if status == 500
    puts error.backtrace  if status == 500

    text ||= 'OK'             if status == 200
    text ||= 'Created'        if status == 201
    text ||= 'Not found'      if status == 404
    text ||= 'Access denied'  if status == 401
    text ||= error.message    if status == 500

    text = text.full_errors if text.respond_to?(:full_errors)

    @status ||= status

    resp = Jbuilder.encode do |json|
      envelope(json, status, text)
    end
    render json: resp, status: status
  end

  helper_method :current_ability
  def current_ability
    @current_ability ||= ::AbilityLib::ChannelAbility.new(current_user).tap do |ability|
      ability.merge(::AbilityLib::AccessManagement::GroupAbility.new(current_user))
      ability.merge(::AbilityLib::Blog::CommentAbility.new(current_user))
      ability.merge(::AbilityLib::Blog::ImageAbility.new(current_user))
      ability.merge(::AbilityLib::Blog::PostAbility.new(current_user))
      ability.merge(::AbilityLib::StripeDb::ServiceSubscriptionAbility.new(current_user))
      ability.merge(::AbilityLib::CommentAbility.new(current_user))
      ability.merge(::AbilityLib::OrganizationMembershipAbility.new(current_user))
      ability.merge(::AbilityLib::OrganizationAbility.new(current_user))
      ability.merge(::AbilityLib::PendingRefundAbility.new(current_user))
      ability.merge(::AbilityLib::RecordingAbility.new(current_user))
      ability.merge(::AbilityLib::ReviewAbility.new(current_user))
      ability.merge(::AbilityLib::SessionAbility.new(current_user))
      ability.merge(::AbilityLib::SessionInvitedImmersiveParticipantshipAbility.new(current_user))
      ability.merge(::AbilityLib::SessionInvitedLivestreamParticipantshipAbility.new(current_user))
      ability.merge(::AbilityLib::SubscriptionAbility.new(current_user))
      ability.merge(::AbilityLib::UserAbility.new(current_user))
      ability.merge(::AbilityLib::VideoAbility.new(current_user))
    end
  end

  protected

  def access_management_group_ability
    @access_management_group_ability ||= ::AbilityLib::AccessManagement::GroupAbility.new(current_user)
  end

  def blog_comment_ability
    @blog_comment_ability ||= ::AbilityLib::Blog::CommentAbility.new(current_user)
  end

  def blog_image_ability
    @blog_image_ability ||= ::AbilityLib::Blog::ImageAbility.new(current_user)
  end

  def blog_post_ability
    @blog_post_ability ||= ::AbilityLib::Blog::PostAbility.new(current_user)
  end

  def comment_ability
    @comment_ability ||= ::AbilityLib::CommentAbility.new(current_user)
  end

  def stripe_db_service_subscription_ability
    @stripe_db_service_subscription_ability ||= ::AbilityLib::StripeDb::ServiceSubscriptionAbility.new(current_user)
  end

  def channel_ability
    @channel_ability ||= ::AbilityLib::ChannelAbility.new(current_user)
  end

  def organization_ability
    @organization_ability ||= ::AbilityLib::OrganizationAbility.new(current_user)
  end

  def organization_membership_ability
    @organization_membership_ability ||= ::AbilityLib::OrganizationMembershipAbility.new(current_user)
  end

  def pending_refund_ability
    @pending_refund_ability ||= ::AbilityLib::PendingRefundAbility.new(current_user)
  end

  def recording_ability
    @recording_ability ||= ::AbilityLib::RecordingAbility.new(current_user)
  end

  def review_ability
    @review_ability ||= ::AbilityLib::ReviewAbility.new(current_user)
  end

  def session_ability
    @session_ability ||= ::AbilityLib::SessionAbility.new(current_user)
  end

  def session_invited_immersive_participantship_ability
    @session_invited_immersive_participantship_ability ||= ::AbilityLib::SessionInvitedImmersiveParticipantshipAbility.new(current_user)
  end

  def session_invited_livestream_participantship_ability
    @session_invited_livestream_participantship_ability ||= ::AbilityLib::SessionInvitedLivestreamParticipantshipAbility.new(current_user)
  end

  def subscription_ability
    @subscription_ability ||= ::AbilityLib::SubscriptionAbility.new(current_user)
  end

  def user_ability
    @user_ability ||= ::AbilityLib::UserAbility.new(current_user)
  end

  def video_ability
    @video_ability ||= ::AbilityLib::VideoAbility.new(current_user)
  end

  private

  def authorization_only_for_organization
    render_json 401, 'Only organization can get access here' if current_organization.blank? || jwt_decoder.type != ::Auth::Jwt::Types::ORGANIZATION
  end

  def authorization_only_for_user
    render_json 401, 'Only user can get access here' if current_user.blank?
  end

  def authorization_only_for_guest
    render_json 401, 'Only guest can get access here' if current_guest.blank?
  end

  def authorization_only_for_user_or_guest
    render_json 401, 'Only user or guest can get access here' if current_user.blank? && current_guest.blank?
  end

  def offset_limit
    @offset = ((params[:offset].to_i) >= 0) ? params[:offset].to_i : 0
    @limit = (params[:limit].to_i >= 1) ? params[:limit].to_i : 20
  end
end
