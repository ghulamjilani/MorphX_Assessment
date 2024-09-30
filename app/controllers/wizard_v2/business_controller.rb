# frozen_string_literal: true

class WizardV2::BusinessController < WizardV2::ApplicationController
  before_action :authenticate_user!
  before_action :check_subscription

  def show
    current_user.create_presenter! if current_user.presenter.blank?
    current_user.presenter.update({ last_seen_become_presenter_step: Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP2 })

    @business = current_user.organization || Organization.new
    current_user.service_subscription.update(organization_id: @business.id) if current_user.service_subscription.present? && @business.persisted?
    social_links = @business.social_links
    SocialLink::Providers::ORDERED_ALL.each do |provider|
      social_links.find { |sl| sl.provider.eql?(provider) } or
        social_links.build(entity: @business, provider: provider)
    end
  end

  def update
    @business = current_user.organization || current_user.build_organization
    @business.attributes = business_attributes
    if @business.save
      current_user.service_subscription.update(organization_id: @business.id) if current_user.service_subscription.present?
      current_user.update(current_organization_id: @business.id)
      respond_to do |format|
        format.html do
          flash[:success] = 'Business Saved'
          redirect_to wizard_v2_channel_path
        end
        format.json { render json: { redirect_path: wizard_v2_channel_url }, status: 200 }
      end
    else
      respond_to do |format|
        format.html do
          flash[:error] = @business.pretty_errors
          @business.logo&.remove_image!
          render :show
        end
        format.json { render json: @business.pretty_errors, status: 422 }
      end
    end
  end

  private

  def business_attributes
    if params[:organization].present?
      params.require(:organization).permit(
        :name,
        :website_url,
        :description,
        :tagline,
        social_links_attributes: %i[link provider id],
        logo_attributes: %i[crop_x crop_y crop_w crop_h rotate image],
        cover_attributes: %i[crop_x crop_y crop_w crop_h rotate image]
      ).tap do |p|
        p.delete(:logo_attributes) if p[:logo_attributes].blank? || p[:logo_attributes][:image].blank?
        p.delete(:cover_attributes) if p[:cover_attributes].blank? || p[:cover_attributes][:image].blank?
      end
    end
  end

  def check_subscription
    if Rails.application.credentials.global.dig(:service_subscriptions, :enabled) &&
       !current_user.service_subscriptions.exists?(service_status: %i[trial trial_suspended active grace suspended pending_deactivation])
      respond_to do |format|
        format.html do
          redirect_to spa_pricing_index_url
        end
        format.json { render json: { message: 'No subscription found' }, status: 422 }
      end
    end
  end
end
