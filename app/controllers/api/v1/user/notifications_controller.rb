# frozen_string_literal: true

class Api::V1::User::NotificationsController < Api::V1::User::ApplicationController
  def index
    query = current_user.reminder_notifications
    query = query.joins(:receipts).where(mailboxer_receipts: { is_read: params[:is_read] }) unless params[:is_read].nil?
    query = query.preload(notified_object: :image)
    @count = query.count
    order_by = %w[created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
    @notifications = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
  end

  def show
    @notification = current_user.reminder_notifications.find(params[:id])
  end

  def mark_as_read
    query = current_user.reminder_notifications.readonly(false)
    query = query.where(id: params[:id]) unless params[:id].to_s.casecmp('all').zero?
    ids = query.pluck :id
    current_user.mark_reminder_notifications_as_read(ids)
    render_json 200, ids
  end

  def mark_as_unread
    query = current_user.reminder_notifications.readonly(false)
    query = query.where(id: params[:id]) unless params[:id].to_s.casecmp('all').zero?
    ids = query.pluck :id
    current_user.mark_reminder_notifications_as_unread(ids)
    render_json 200, ids
  end

  def destroy
    query = current_user.reminder_notifications.readonly(false)
    query = query.where(id: params[:id]) unless params[:id].to_s.casecmp('all').zero?
    ids = query.pluck :id
    query.destroy_all
    render_json 200, ids
  end
end
