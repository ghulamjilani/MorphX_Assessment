# frozen_string_literal: true

module ControllerConcerns::Api::V1::Auth::RefOrganization
  extend ActiveSupport::Concern

  private

  def ref_model
    return nil if params[:ref_model].blank?

    permitted_ref_model_params = params.require(:ref_model).permit(:id, :type)
    return nil if permitted_ref_model_params[:id].blank? || permitted_ref_model_params[:type].blank?

    @ref_model ||= permitted_ref_model_params[:type].classify.constantize.find(permitted_ref_model_params[:id])
  end

  def ref_organization
    @ref_organization ||= case ref_model.class.name
                          when 'Channel', 'Session', 'Blog::Post'
                            @ref_model.organization
                          when 'Video'
                            @ref_model.session&.organization
                          when 'Recording'
                            @ref_model.channel.organization
                          when 'Organization'
                            @ref_model
                          end
  end

  def add_guest_membership(user)
    return false if user.current_organization_id?
    return false unless Rails.application.credentials.backend.dig(:organization_membership, :guests, :enabled)
    return false unless ref_organization
    return false if ref_organization.organization_memberships.exists?(user: user)

    ref_organization.organization_memberships_guests.create!(user: user, status: ::OrganizationMembership::Statuses::ACTIVE)
  end
end
