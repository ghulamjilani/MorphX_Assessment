# frozen_string_literal: true

class OrganizationsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_company, only: %i[edit update]

  def new
    authorize!(:create_company, current_user)
    @organization = current_user.build_organization
    @title = 'Create company'
    prepare_soc_links
    gon.default_user_logo = User.new.medium_avatar_url
    render :edit
  end

  def create
    authorize!(:create_company, current_user)
    @organization = current_user.build_organization

    @organization.attributes = company_attributes
    @title = 'Create company'
    if @organization.save
      flash[:success] = I18n.t('controllers.companies.create_success')
      respond_to do |format|
        format.json { render json: { path: @organization.absolute_path } }
        format.html { redirect_to @organization.relative_path }
      end
    else
      logger.debug @organization.errors.full_messages.inspect
      flash[:error] = @organization.errors.full_messages.join(', ')
      respond_to do |format|
        format.json { render json: @organization.errors.full_messages.join(', '), status: 422 }
        format.html { render :edit }
      end
    end
  end

  def edit
    authorize!(:edit, @organization)
    @title = 'Edit company'
    prepare_soc_links
    gon.default_user_logo = User.new.medium_avatar_url
  end

  def update
    authorize!(:edit, @organization)

    @organization.attributes = company_attributes
    @title = 'Edit company'
    if @organization.save
      flash[:success] = I18n.t('controllers.companies.update_success')
      respond_to do |format|
        format.json { render json: { path: company_dashboard_path } }
        format.html { redirect_to company_dashboard_path }
      end
    else
      logger.debug @organization.errors.full_messages.inspect
      flash[:error] = @organization.errors.full_messages.join(', ')
      respond_to do |format|
        format.json { render json: @organization.errors.full_messages.join(', '), status: 422 }
        format.html { render :edit }
      end
    end
  end

  def leave
    organization = Organization.find(params[:id])

    membership = organization.organization_memberships_active.where(user_id: current_user.id).first
    membership.destroy if membership.present?

    presenterships = organization.channel_invited_presenterships.where(presenter_id: current_user.presenter_id)
    if presenterships.present?
      presenterships.map(&:destroy)
    end

    if membership.present? || presenterships.present?
      flash[:success] = "You have been removed from the #{organization.name}"
    end

    redirect_back fallback_location: dashboard_path
  end

  def accept_invitation
    @organization = Organization.find(params[:id])

    authorize!(:accept_or_reject_invitation, @organization)
    organization_membership = @organization.organization_memberships_participants.pending.find_by(user: current_user)
    if organization_membership.active!
      respond_to do |format|
        format.json { render json: { id: params[:id] } }
        format.html do
          flash[:success] = I18n.t('controllers.mark_invitation_as_accepted_success')
          redirect_back fallback_location: @organization.absolute_path
        end
      end
    else
      pretty_errors = organization_membership.pretty_errors
      errors_list = organization_membership.errors.full_messages.join('; ')
      organization_membership.destroy if errors_list.include? 'owner cannot be invited'
      respond_to do |format|
        format.json { render json: { id: params[:id], errors: pretty_errors } }
        format.html do
          flash[:error] = I18n.t('controllers.mark_invitation_as_accepted_fail', errors_list: errors_list)
          redirect_back fallback_location: @organization.absolute_path
        end
      end
    end
  end

  def reject_invitation
    @organization = Organization.find(params[:id])

    authorize!(:accept_or_reject_invitation, @organization)
    organization_membership = @organization.organization_memberships_participants.pending.find_by(user: current_user)
    if organization_membership.cancelled!
      respond_to do |format|
        format.json { render json: { id: params[:id] } }
        format.html do
          flash[:success] = I18n.t('controllers.sessions.rejected_invitation')
          redirect_back fallback_location: dashboard_path
        end
      end
    else
      pretty_errors = organization_membership.pretty_errors
      errors_list = organization_membership.errors.full_messages.join('; ')
      organization_membership.destroy if errors_list.include? 'owner cannot be invited'
      respond_to do |format|
        format.json { render json: { id: params[:id], errors: pretty_errors } }
        format.html do
          flash[:error] = I18n.t('controllers.sessions.reject_invitation_fail', errors_list: errors_list)
          redirect_back fallback_location: @organization.absolute_path
        end
      end
    end
  end

  def set_current
    organization = Organization.find(params[:id])
    authorize!(:set_current, organization)
    current_user.current_organization_id = organization.id
    current_user.save(validate: false)
    redirect_link = organization.user_id == current_user.id ? dashboard_path : organization.relative_path
    respond_to do |format|
      format.js { head :ok }
      format.json { head :ok }
      format.html { redirect_to redirect_link }
    end
  end

  private

  def load_company
    @organization = Organization.find(params[:id])

    # NOTE: @current_organization uses in layouts/application/organization_custom_styles partial for customization pages
    @current_organization = @organization
  end

  def company_json
    return {} unless @organization

    json = @organization.as_json.slice('id', 'name', 'website', 'tagline', 'description')
    json[:logo] = @organization.logo.as_json if @organization.logo
    json[:cover] = @organization.cover.as_json if @organization.cover
    json[:relative_path] = @organization.relative_path unless @organization.new_record?
    json
  end

  def members_json
    return [] if @organization.new_record?

    @organization.members_data
  end

  def company_attributes
    if params[:organization].present?
      params.require(:organization).permit(
        :name,
        :website_url,
        :description,
        :tagline,
        :multiroom_status,
        :embed_domains,
        :stop_no_stream_sessions,
        social_links_attributes: %i[link provider id],
        logo_attributes: %i[crop_x crop_y crop_w crop_h rotate image],
        cover_attributes: %i[crop_x crop_y crop_w crop_h rotate image]
      ).tap do |p|
        p.delete(:logo_attributes) unless p[:logo_attributes] && p[:logo_attributes][:image]
        p.delete(:cover_attributes) unless p[:cover_attributes] && p[:cover_attributes][:image]
      end
    end
  end

  def prepare_soc_links
    social_links = @organization.social_links
    SocialLink::Providers::ORDERED_ALL.each do |provider|
      social_links.find { |sl| sl.provider.eql?(provider) } or
        social_links.build(entity: @organization, provider: provider)
    end
  end
end
