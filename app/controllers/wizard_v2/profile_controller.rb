# frozen_string_literal: true

class WizardV2::ProfileController < WizardV2::ApplicationController
  before_action :authenticate_user!, except: %i[show update]
  skip_before_action :check_if_completed_creator, unless: :user_signed_in?

  def show
    @user = current_user || User.new
    @user.build_user_account unless @user.user_account
    if @user.persisted?
      @user.create_presenter! unless @user.presenter
      @user.presenter.update({ last_seen_become_presenter_step: Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP1 })
    end
    if cookies[:country_code].to_s.strip.present? && @user.user_account.country.blank?
      @user.user_account.country = cookies[:country_code]
    end
  end

  def update
    @user = user_signed_in? ? current_user : User.new
    @interactor = BecomePresenter::SaveUserInfo.new(@user, user_attributes)
    if @interactor.execute
      user = @interactor.user
      if @interactor.is_new?
        vs_attrs = {
          user_id: user.id,
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
      end
      unless user_signed_in?
        sign_in(:user, @user)
      end
      redirect_to_url = if !Rails.application.credentials.global.dig(:service_subscriptions, :enabled) || current_user.service_subscription.present?
                          wizard_v2_business_url
                        else
                          spa_pricing_index_url
                        end
      respond_to do |format|
        format.html do
          flash[:success] = 'Profile Saved'
          redirect_to redirect_to_url
        end
        format.json { render json: { redirect_path: redirect_to_url }, status: 200 }
      end
    else
      errors = @interactor.errors
      respond_to do |format|
        format.html do
          flash[:error] = errors
          render :show
        end
        format.json { render json: errors, status: 422 }
      end
    end
  end

  private

  def user_json(user)
    json = user.as_json.slice('id', 'first_name', 'last_name', 'email', 'slug')
    if user.user_account
      json.merge!(user.user_account.as_json.slice('bio'))
    end
    json[:display_name] = user.display_name
    json[:logo] = user.medium_avatar_url
    json[:current_user] = (current_user == user)
    json[:presenter_id] = user.presenter_id
    json
  end

  def user_attributes
    if params[:user].present?
      params.require(:user).permit(
        'birthdate(1i)',
        'birthdate(2i)',
        'birthdate(3i)',
        :birthdate,
        :email,
        :first_name,
        :last_name,
        :gender,
        :password,
        :manually_set_timezone,
        :tzinfo,
        :language,
        image_attributes: %i[crop_x crop_y crop_w crop_h rotate original_image],
        user_account_attributes: %i[country phone bio tagline talent_list available_by_request_for_live_vod
                                    original_bg_image crop_x crop_y crop_w crop_h rotate]
      ).tap do |attributes|
        if current_user && current_user.email.to_s.present?
          attributes.delete 'email'
        end
        attributes['gender']&.downcase!
        attributes['password_confirmation'] = attributes['password'] if attributes['password']
        attributes.delete(:image_attributes) unless attributes[:image_attributes] && attributes[:image_attributes][:original_image].present?
        attributes[:birthdate] = Date.strptime(attributes[:birthdate], '%m/%d/%Y') if attributes[:birthdate].present?
      rescue ArgumentError => e
        Rails.logger.debug "attributes: #{attributes.inspect}"
        Rails.logger.debug e.message
      end
    end
  end
end
