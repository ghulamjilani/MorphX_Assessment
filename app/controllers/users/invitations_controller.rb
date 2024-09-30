# frozen_string_literal: true

class Users::InvitationsController < Devise::InvitationsController
  # see devise_invitable's original controler
  def edit
    session[RETURN_TO_AFTER_CONNECTING_ACCOUNT] = params[:return_to_after_connecting_account]

    set_minimum_password_length
    resource.invitation_token = params[:invitation_token]

    respond_to do |format|
      format.json do
        if resource.errors.blank?
          render json: { first_name: resource.first_name, last_name: resource.last_name, display_name: resource.display_name, email: resource.email }, status: 200
        else
          render json: resource.errors.full_messages.join('; '), status: 422
        end
      end
      format.html { render :edit }
    end
  end

  def update
    self.resource = accept_resource

    if resource.errors.empty?
      yield resource if block_given?
      flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
      set_flash_message :notice, flash_message

      sign_in(resource_name, resource)
      vs_attrs = {
        user_id: resource.id,
        refc: cookies.permanent.signed[:refc],
        current: cookies[:sbjs_current],
        current_add: cookies[:sbjs_current_add],
        first: cookies[:sbjs_first],
        first_add: cookies[:sbjs_first_add],
        session: cookies[:sbjs_session],
        udata: cookies[:sbjs_udata]
      }
      VisitorSource.track_visitor(cookies.permanent[:visitor_id], vs_attrs)
      Mailer.user_signed_up(resource.id).deliver_later

      json_responder = proc { render json: { location: after_accept_path_for(resource) } }
      html_responder = proc { respond_with resource, location: after_accept_path_for(resource) }

      respond_to do |format|
        format.html(&html_responder)
        format.json(&json_responder)
      end
    else
      respond_with_navigational(resource) { render :edit }
    end
  end

  # overrides devise_invitable's method
  def after_accept_path_for(resource)
    sub = FreeSubscription.find_by(user_id: resource.id)

    @after_accept_path ||= sub&.channel&.absolute_path || session.delete(RETURN_TO_AFTER_CONNECTING_ACCOUNT) || after_sign_in_path_for(resource)
  end

  def invite_resource
    resource_class.invite!(invite_params, current_inviter, &:before_create_generic_callbacks_and_skip_validation)
  end

  private

  def accept_resource
    obj = resource_class.accept_invitation!(update_resource_params)

    # fixes #1903
    if obj
      obj.attributes = user_params
      obj.save!

      if Rails.application.credentials.global[:enterprise] && (organization_membership = obj.organization_memberships_participants.pending.first)
        organization_membership.active!
      end
    end

    obj
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :birthdate, :gender, :email, :password, :manually_set_timezone, user_account_attributes: %i[phone country]).tap do |attrs|
      attrs[:password_confirmation] = attrs[:password]
      attrs[:email] = attrs[:email].to_s.downcase
      attrs[:manually_set_timezone] = params[:user][:timezone]
    end
  end
end
