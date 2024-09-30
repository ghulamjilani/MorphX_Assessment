# frozen_string_literal: true

class BecomePresenterStepsController < ApplicationController
  include ControllerConcerns::ValidatesRecaptcha

  layout 'become_presenter_steps'
  before_action :authenticate_user!, except: %i[index save_user lets_talk]
  before_action :prepare_presenter, only: %i[log_step2 log_step3]
  before_action :load_channel, only: %i[save_channel_cover save_channel_gallery_image save_channel_link
                                        remove_channel_link remove_channel_image]

  def index
    return redirect_to root_path if user_signed_in? && cannot?(:become_a_creator, current_user)

    @user = current_user ? current_user : User.new
    respond_to do |format|
      format.html do
        if user_signed_in? && @user.presenter.present?
          @user.presenter.update({ last_seen_become_presenter_step: Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP1 })
        end
        @user.build_user_account unless @user.user_account
        if @user.user_account.country.blank?
          # https://lcmsportal.plan.io/issues/2514
          record = IpInfoRecord.where(ip: request.remote_ip).last

          if record.present?
            @user.user_account(country: record.country)
          end
        end
        set_gon_params
      end
    end
  end

  def log_step2
    if current_user.presenter.last_seen_become_presenter_step != Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP3
      current_user.presenter.update({ last_seen_become_presenter_step: Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP2 })
    end
    head :ok
  end

  def log_step3
    current_user.presenter.update({ last_seen_become_presenter_step: Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP3 })
    head :ok
  end

  def continue
    channel = current_user.channels.find(params[:channel_id])
    if params[:list_upon_approval]
      channel.update_attribute(:list_automatically_after_approved_by_admin, true)
    end
    channel.submit_for_review! if channel.draft?
    current_user.presenter.update_attribute(:last_seen_become_presenter_step, nil)
    current_user.touch
    render json: { path: channel.relative_path }
  end

  def lets_talk
    # CAPTCHA
    unless recaptcha_verified?
      render json: { errors: { recaptcha: Recaptcha::Helpers.to_error_message(:verification_failed) } }, status: 422
    end

    Mailer.lets_talk(params.permit(:name, :company, :first_name, :last_name, :email, :phone, :about,
                                   :name, :plan, :configured_autonomous_camera, :multi_instructor_capability,
                                   :single_classes_count, :single_classes_cost, :new_subscriptions_count,
                                   :new_subscriptions_cost, :type)).deliver_later
    head :ok
  end

  # step 1 save
  def save_user
    user = user_signed_in? ? current_user : User.new
    @interactor = BecomePresenter::SaveUserInfo.new(user, user_attributes)
    if @interactor.execute
      user = @interactor.user
      unless user_signed_in?
        sign_in(:user, user)
        @header = render_to_string('layouts/application/_header', formats: [:html], layout: false)
      end
      json = { user: user_json(user), header: @header }
      json[:organization] = company_json(user.organization) if params[:organization]
      render json: json
    else
      errors = @interactor.errors
      render json: errors, status: 422
    end
  end

  # step 1 or 2 save company
  def save_company
    if params[:autosave]
      autosave_company
    else
      @interactor = BecomePresenter::SaveCompany.new(current_user, company_attributes)
      if @interactor.execute
        render json: company_json(@interactor.company)
      else
        errors = @interactor.errors
        render json: errors, status: 422
      end
    end
  end

  # step 2 save/autosave
  def save_channel
    head :ok and return if channel_attributes.blank?

    @interactor = BecomePresenter::SaveChannelInfo.new(current_user, channel_attributes)
    if @interactor.execute
      render json: channel_json(@interactor.channel)
    else
      errors = @interactor.errors
      render json: errors, status: 422
    end
  end

  # step 2 cover autosave
  def save_channel_cover
    @interactor = BecomePresenter::SaveChannelCover.new(current_user, @channel, channel_cover_attributes)
    if @interactor.execute
      render json: @interactor.cover
    else
      errors = @interactor.errors
      render json: errors, status: 422
    end
  end

  # step 2 gallery item autosave
  def save_channel_gallery_image
    @interactor = BecomePresenter::SaveChannelImage.new(current_user, @channel, channel_image_attributes)
    if @interactor.execute
      render json: @interactor.image
    else
      errors = @interactor.errors
      render json: errors, status: 422
    end
  end

  # step 2 gallery item autosave
  def save_channel_link
    @interactor = BecomePresenter::SaveChannelLink.new(current_user, @channel, link_attributes)
    if @interactor.execute
      render json: @interactor.result
    else
      errors = @interactor.errors
      render json: errors, status: 422
    end
  end

  # step 2 gallery item remove
  def remove_channel_image
    @channel.images.find(params[:id]).destroy
    head :ok
  end

  # step 2 gallery item remove
  def remove_channel_link
    @channel.channel_links.find(params[:id]).destroy
    head :ok
  end

  # step 3 my info save/autosave
  def save_user_account
    if params[:autosave]
      autosave_user_account
    else
      @interactor = BecomePresenter::SaveUserAccountInfo.new(current_user, user_account_attributes)
      if @interactor.execute
        render json: { user: user_json(@interactor.user) }
      else
        errors = @interactor.errors
        render json: errors, status: 422
      end
    end
  end

  # step 3 search users on immerss
  # TODO: move to shared
  def search_presenter
    search_query = PgSearchDocument.search(params[:query])
                                   .where(searchable_type: 'User', fake: false)

    ids = limit_offset(search_query).pluck(:searchable_id)

    json_data = User.where(id: ids).map(&:user_data)
    render json: json_data, status: 200
  end

  # Step 3 Got info/Email/Search
  def add_presenter
    @interactor = BecomePresenter::AddPresenter.new(current_user, params)
    if @interactor.execute
      render json: user_json(@interactor.user)
    else
      errors = @interactor.errors
      render json: errors, status: 422
    end
  end

  # Step 3 remove presenter
  def remove_presenter
    return head :ok if current_user.id == params[:user_id]

    channel = Channel.find(params[:channel_id])
    user = User.find(params[:user_id])
    if channel.organization_id
      channel.organization.organization_memberships_active.find_by(user_id: user.id).try(:destroy)
    end
    channel.channel_invited_presenterships.find_by(presenter_id: user.presenter.id).try(:destroy)
    head :ok
  end

  private

  def load_channel
    @channel = Channel.find(params[:channel_id])
    unless @channel.organization_id == current_user.organization.try(:id)
      head :unauthorized
    end
  end

  def set_gon_params
    gon.user = user_json(@user)

    gon.user_info_ready = @user.user_info_ready?
    gon.user_info_ready = @user.user_info_ready?
    gon.channel_ready = @user.channel_ready?
    gon.company_info_ready = @user.company_info_ready?

    gon.max_images_size = SystemParameter.channel_images_max_count.to_i
    gon.max_links_size = SystemParameter.channel_links_max_count.to_i
    gon.default_user_logo = User.new.medium_avatar_url
    gon.default_company_logo = Organization.new.small_logo_url

    gon.timezones = User.available_timezones.map { |tz| { name: tz.to_s, value: tz.tzinfo.name } }.compact
    gon.countries = ISO3166::Country.all.map do |c|
                      { name: c.translation(I18n.locale) || c.name, value: c.alpha2 }
                    end.sort_by { |h| h[:name] }

    gon.channel_categories = channel_categories
    gon.channel_types = channel_types

    if user_signed_in?
      gon.company = company_json(@user.organization)
      gon.channel = channel_json(@user.channel)
      gon.presenters = presenters_json
    else
      gon.presenters = []
    end
  end

  # autosave
  def autosave_profile
    return head :bad_request if user_attributes.blank?

    if user_attributes.has_key?(:user_account_attributes)
      current_user.build_user_account if current_user.user_account.blank?
      data = user_attributes[:user_account_attributes].first
      current_user.user_account_attributes = user_attributes[:user_account_attributes]
      if current_user.user_account.errors[data.first].empty?
        current_user.user_account.update_attribute(*data)
        head :ok
      else
        render json: current_user.user_account.errors[attribute.first].join(', '), status: 422
      end
    else
      data = user_attributes.first
      current_user.attributes = user_attributes
      if current_user.errors[data.first].empty?
        current_user.update_attribute(*user_attributes.first)
        head :ok
      else
        render json: current_user.errors[user_attributes.first].join(', '), status: 422
      end
    end
  end

  def autosave_user_account
    return head :bad_request if user_account_attributes.blank?

    current_user.build_user_account if current_user.user_account.blank?
    data = user_account_attributes.first
    current_user.user_account_attributes = user_account_attributes
    if current_user.user_account.errors[data.first].empty?
      current_user.user_account.update_attribute(*data)
      head :ok
    else
      render json: current_user.user_account.errors[attribute.first].join(', '), status: 422
    end
  end

  def autosave_company
    return head :bad_request if !current_user.organization || company_attributes.blank?

    company = current_user.organization
    company.attributes = company_attributes
    if company.save
      render json: company_json(company)
    else
      render json: company.errors.full_messages.join(', '), status: 422
    end
  end

  # permitted attrs
  def user_attributes
    if params[:user].present?
      params.require(:user).permit(
        :birthdate,
        :email,
        :first_name,
        :last_name,
        :gender,
        :password,
        :manually_set_timezone,
        image_attributes: %i[crop_x crop_y crop_w crop_h rotate original_image],
        user_account_attributes: %i[country phone bio tagline talent_list available_by_request_for_live_vod
                                    crop_x crop_y crop_w crop_h rotate original_bg_image]
      ).tap do |attributes|
        if attributes['password']
          attributes['password_confirmation'] = attributes['password']
        end
        if params['user']['birthdate_y'] && params['user']['birthdate_m'] && params['user']['birthdate_d']
          attributes['birthdate'] =
            Time.new(params['user']['birthdate_y'], params['user']['birthdate_m'], params['user']['birthdate_d'])
        end
      rescue ArgumentError => e
        Rails.logger.debug "attributes: #{attributes.inspect}"
        Rails.logger.debug e.message
      end
    end
  end

  def company_attributes
    if params[:organization].present?
      params.require(:organization).permit(
        :name,
        :website_url,
        :description,
        :tagline,
        cover_attributes: %i[crop_x crop_y crop_w crop_h rotate original],
        logo_attributes: %i[crop_x crop_y crop_w crop_h rotate original]
      )
    end
  end

  def channel_attributes
    if params[:channel].present?
      params.require(:channel).permit(
        :id,
        :title,
        :description,
        :category_id,
        :channel_type_id,
        :tag_list,
        :organization_id,
        cover_attributes: %i[id crop_x crop_y crop_w crop_h rotate is_main image],
        images_attributes: %i[id crop_x crop_y crop_w crop_h rotate is_main description image]
      )
    end
  end

  def channel_image_attributes
    if params[:image].present?
      params.require(:image).permit(:id, :crop_x, :crop_y, :crop_w, :crop_h, :rotate, :is_main, :description, :image)
    end
  end

  def channel_cover_attributes
    if params[:cover].present?
      params.require(:cover).permit(:id, :crop_x, :crop_y, :crop_w, :crop_h, :rotate, :is_main, :image)
    end
  end

  def link_attributes
    params.require(:channel_link).permit(:id, :url, :description, :place_number) if params[:channel_link].present?
  end

  def user_account_attributes
    if params[:user_account].present?
      params.require(:user_account).permit(
        :tagline,
        :bio,
        :talent_list,
        :available_by_request_for_live_vod,
        :crop_x,
        :crop_y,
        :crop_w,
        :crop_h,
        :rotate,
        :original_bg_image,
        logo: %i[crop_x crop_y crop_w crop_h rotate original_image]
      )
    end
  end

  # json data
  def user_json(user)
    json = user.as_json.slice('id', 'first_name', 'last_name', 'email', 'gender', 'manually_set_timezone', 'slug')
    if user.user_account
      json.merge!(user.user_account.as_json.slice('country', 'tagline', 'bio', 'available_by_request_for_live_vod',
                                                  'bg_image_url'))
      json[:talent_list] = user.user_account.talent_list.to_s
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

  def company_json(organization)
    return {} unless organization

    json = organization.as_json.slice('id', 'name', 'website', 'tagline', 'description')
    json[:logo] = organization.logo.as_json if organization.logo
    json[:cover] = organization.cover.as_json if organization.cover
    json
  end

  def channel_json(channel)
    return {} unless channel

    json = channel.as_json.slice('id', 'title', 'description', 'category_id', 'channel_type_id')

    json[:cover] = channel.cover.gallery_item if channel.cover
    # Materials include cover image at 0 index for carousel so lets exclude it
    json[:gallery] = channel.materials.reject { |h| h[:is_main] }

    json[:tag_list] = channel.tag_list.join(',')
    json[:owner_type] = channel.owner_type
    json
  end

  def presenters_json
    channel = @user.channel
    presenters = if channel
                   if channel.organization_id
                     channel.organization.employees.collect(&:user_data)
                   else
                     channel.users.collect(&:user_data)
                   end
                 else
                   []
                 end
    if current_user
      presenters.each { |user| user[:current_user] = user['id'] == current_user.id }
    end
    presenters
  end

  def channel_categories
    ChannelCategory.all.order(featured: :desc, name: :asc).collect { |c| { name: c.name, value: c.id } }
  end

  def channel_types
    ChannelType.all.order(description: :asc).collect { |c| { name: c.description, value: c.id } }
  end

  def prepare_presenter
    current_user.create_presenter if current_user && current_user.presenter.blank?
  end

  def limit_offset(query)
    page = (params[:page] || 1).to_i
    page = 1 if page < 1
    limit = (params[:per_page] || 15).to_i
    limit = 15 if limit < 1
    offset = limit * (page - 1)

    query.limit(limit).offset(offset)
  end
end
