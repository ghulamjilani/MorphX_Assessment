# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  include ControllerConcerns::RedirectUtils

  before_action :configure_permitted_parameters, if: :devise_controller?

  def new
    session['autodisplay_modal'] = LandingHelper::SIGN_UP_MODAL
    redirect_to root_path
  end

  def create
    build_resource(sign_up_params)
    if params.has_key?(:embed)
      resource.skip_birthdate_validation = true
      resource.skip_gender_validation = true
    end
    if resource.save
      yield resource if block_given?
      vs_attrs = {
        user_id: resource.id,
        refc: cookies.permanent.signed[:refc],
        current: cookies[:sbjs_current],
        current_add: cookies[:sbjs_current_add],
        first: cookies[:sbjs_first],
        first_add: cookies[:sbjs_first_add],
        session: cookies[:sbjs_session],
        udata: cookies[:sbjs_udata],
        tzinfo: cookies[:tzinfo]
      }
      VisitorSource.track_visitor(cookies.permanent[:visitor_id], vs_attrs)
      Mailer.user_signed_up(resource.id).deliver_later

      # fixes "Become a presenter call to action"
      # expect user to confirm his email before proceeding
      ###
      if request.referer.present? && request.referer.include?('presenter_steps')
        Rails.cache.write("after_confirmation_path_for/#{resource.id}", presenter_steps_path)
        set_flash_message :alert, :signed_up_but_unconfirmed
        expire_data_after_sign_in!

        respond_to do |format|
          format.html { respond_with resource, location: after_inactive_sign_up_path_for(resource) }
          format.json do
            render 'create', locals: { redirect_path: after_inactive_sign_up_path_for(resource), user: resource },
                             status: 201
          end
        end
        return
      end
      ###

      if resource.active_for_authentication?
        set_flash_message :success, :signed_up
        sign_up(resource_name, resource)
        redirect_path = after_sign_up_path_for(resource)
      else
        set_flash_message :alert, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        redirect_path = after_inactive_sign_up_path_for(resource)
      end
    else
      Rails.logger.debug resource.errors.full_messages.inspect

      clean_up_passwords resource
      redirect_path = '/'
      # TODO: add html_handler if/when you need to handle validation errors in feature specs
    end
    if params.has_key?(:embed)
      if resource&.new_record?
        render json: resource.errors.full_messages.join('. '), status: 422
      else
        render json: { user: resource&.as_json(only: :id) }
      end
      return
    end
    respond_to do |format|
      format.html { respond_with resource, location: redirect_path }
      format.json do
        render 'create', locals: { redirect_path: redirect_path, user: resource },
                         status: (resource.new_record? ? 400 : 201)
      end
    end
  end

  protected

  # The path used after sign up. You need to overwrite this method
  # in your own RegistrationsController.
  def after_sign_up_path_for(resource)
    after_sign_in_path_for(resource)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: user_params)
  end

  def user_params
    %i[
      birthdate
      email
      email_confirmation
      first_name
      gender
      last_name
      password
      time_format
      manually_set_timezone
      tzinfo
    ]
  end

  # Build a devise resource passing in the session. Useful to move
  # temporary session data to the newly created user.
  def build_resource(hash = nil)
    existing_invited_user_with_incomplete_profile = User.where(sign_in_count: 0).where(email: hash[:email]).last
    # fixes #1903
    if existing_invited_user_with_incomplete_profile
      self.resource = existing_invited_user_with_incomplete_profile
      resource.attributes = hash if hash.present?

      # otherwise it fails to log user in due to blank confirmation token
      if resource.valid? && resource.confirmation_token.blank?
        resource.send_confirmation_instructions
      end
    else
      self.resource = resource_class.new_with_session(hash || {}, session)
      resource.before_create_generic_callbacks_without_skipping_validation
    end
  end
end
