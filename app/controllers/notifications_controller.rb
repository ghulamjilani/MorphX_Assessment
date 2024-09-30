# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :authenticate_user!

  before_action :set_current_organization
  before_action :remove_counter_cache, except: [:index]

  def index
    per_page = (params[:per_page] || 20).to_i
    per_page = 20 if per_page > 20
    @notifications = current_user.reminder_notifications.preload(:receipts).page(params[:page]).per(per_page)
    respond_to do |format|
      format.html
      format.json
    end
  end

  def destroy
    notification = current_user.reminder_notifications.readonly(false).find(params[:id])
    notification.destroy
    flash[:success] = I18n.t('controllers.notifications.single_destroy_success')

    redirect_to notifications_path
  end

  def destroy_selected
    current_user.reminder_notifications.where(id: params[:notifications].values.pluck(:id)).readonly(false).destroy_all
    flash[:success] = I18n.t('controllers.notifications.multi_destroy_success')

    redirect_to notifications_path
  end

  def destroy_all
    current_user.reminder_notifications.readonly(false).destroy_all
    flash[:success] = I18n.t('controllers.notifications.multi_destroy_success')

    respond_to do |format|
      format.js
      format.html { redirect_to notifications_path }
    end
  end

  def destroy_read
    current_user.reminder_notifications.joins(:receipts).where(mailboxer_receipts: { is_read: true }).readonly(false).destroy_all
    flash[:success] = I18n.t('controllers.notifications.multi_destroy_success')

    redirect_to notifications_path
  end

  def mark_as_read
    notification = current_user.reminder_notifications.readonly(false).find(params[:id])
    current_user.mark_reminder_notifications_as_read([notification.id])
    respond_to do |format|
      format.js { head :ok }
      format.html do
        flash[:success] = I18n.t('controllers.notifications.multi_marked_as_read')
        redirect_to notifications_path
      end
    end
  end

  def mark_as_unread
    notification = current_user.reminder_notifications.readonly(false).find(params[:id])
    current_user.mark_reminder_notifications_as_unread([notification.id])
    respond_to do |format|
      format.js { head :ok }
      format.html do
        flash[:success] = I18n.t('controllers.notifications.multi_marked_as_read')
        redirect_to notifications_path
      end
    end
  end

  def mark_all_as_read
    ids = current_user.reminder_notifications.pluck(:id)
    current_user.mark_reminder_notifications_as_read(ids)

    flash[:success] = I18n.t('controllers.notifications.multi_marked_as_read')

    respond_to do |format|
      format.js
      format.html { redirect_back fallback_location: root_path }
    end
  end

  def bulk_read
    ids = params[:ids]

    raise ArgumentError if ids.blank?

    current_user.mark_reminder_notifications_as_read(ids)

    head :ok
  end

  private

  def remove_counter_cache
    Rails.cache.delete(current_user.new_notifications_count_cache_key)
  end

  def set_current_organization
    @current_organization = @organization = current_user&.current_organization
  end
end
