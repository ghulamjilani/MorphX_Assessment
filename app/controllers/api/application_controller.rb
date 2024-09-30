# frozen_string_literal: true

class Api::ApplicationController < ActionController::Base
  include ControllerConcerns::JsonGlobal
  acts_as_token_authentication_handler_for User
  respond_to :json

  helper_method :current_ability
  def current_ability
    @current_ability ||= ::AbilityLib::ChannelAbility.new(current_user).tap do |ability|
      ability.merge(::AbilityLib::AccessManagement::GroupAbility.new(current_user))
      ability.merge(::AbilityLib::Blog::CommentAbility.new(current_user))
      ability.merge(::AbilityLib::Blog::ImageAbility.new(current_user))
      ability.merge(::AbilityLib::Blog::PostAbility.new(current_user))
      ability.merge(::AbilityLib::StripeDb::ServiceSubscriptionAbility.new(current_user))
      ability.merge(::AbilityLib::CommentAbility.new(current_user))
      ability.merge(::AbilityLib::OrganizationAbility.new(current_user))
      ability.merge(::AbilityLib::OrganizationMembershipAbility.new(current_user))
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

  def offset_limit
    @offset = ((params[:offset].to_i) >= 0) ? params[:offset].to_i : 0
    @limit = (1..100).cover?(params[:limit].to_i) ? params[:limit].to_i : 20
    @offset_present = true
  end
end
