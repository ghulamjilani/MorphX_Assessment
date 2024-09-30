# frozen_string_literal: true

class Spa::ApplicationController < ActionController::Base
  layout 'spa_application'
  include ControllerConcerns::GoService
  include ControllerConcerns::EverflowTracking
  include ControllerConcerns::Api::V1::CookieAuth
  before_action :set_current_organization

  helper_method :current_ability

  private

  def set_current_organization
    @current_organization = @organization = current_user&.current_organization
  end

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
end
