# frozen_string_literal: true

class Api::V1::Public::OrganizationsController < Api::V1::Public::ApplicationController
  before_action :set_organization, only: [:show]

  def index
    query = ::Organization.not_fake
    query = query.where(show_on_home: params[:show_on_home]) unless params[:show_on_home].nil?
    query = query.where(hide_on_home: false) unless params[:hide_on_home].nil?
    @count = query.count
    order_by = if %w[created_at views_count].include?(params[:order_by])
                 params[:order_by]
               else
                 'views_count'
               end

    promo_order = params[:promo_weight].blank? ? '' : 'CASE WHEN ((organizations.promo_weight <> 0 AND organizations.promo_start IS NULL AND organizations.promo_end IS NULL) OR (organizations.promo_start < now() AND now() < organizations.promo_end)) THEN 100 + organizations.promo_weight ELSE 0 END DESC, '
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
    @organizations = query.order(Arel.sql("#{promo_order}#{order_by} #{order}")).limit(@limit).offset(@offset).preload(:logo, :user, :company_setting, :cover, user: :image)
  end

  def show
    @following = current_user.present? && current_user.following?(@organization)
    @owned_channels = @organization.all_channels.visible_for_user(current_user).approved.listed.not_fake.preload(
      :cover, :logo, :category, :taggings, :channel_links, :images
    )
    @social_links = @organization.social_links
    # @organization.log_daily_activity(:view, owner: current_user) if current_user.present?
  end

  def default_location
    @organization = Organization.friendly.find(params[:id])
    @default_location = organization_default_user_path(@organization)
  end

  private

  def set_organization
    @organization = Organization.preload(:logo, :social_links).friendly.find(params[:id])
  end
end
