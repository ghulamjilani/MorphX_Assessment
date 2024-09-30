# frozen_string_literal: true

class Api::V1::User::FreeSubscriptionsController < Api::V1::ApplicationController
  def index
    return render_json(403, I18n.t('controllers.free_subscriptions_controller.errors.owner_action')) unless current_user.current_organization.user == current_user || can?(:manage_channel_subscription, current_user.current_organization)
    return render_json(403, I18n.t('controllers.free_subscriptions_controller.errors.no_permissions')) unless current_user.current_organization.enable_free_subscriptions

    @free_subscriptions = ::FreeSubscription.joins(free_plan: :channel)
                                            .joins(:user)
                                            .where(channels: { organization_id: current_user.current_organization.id })
                                            .includes(:user, free_plan: :channel).order(created_at: :desc)
    @count = @free_subscriptions.count
    @free_subscriptions = @free_subscriptions.limit(@limit).offset(@offset)
  end

  def new
    @channels = current_user.current_organization.channels.approved.not_archived.order(title: :asc)
  end

  def create
    return render_json(403, I18n.t('controllers.free_subscriptions_controller.errors.owner_action')) unless current_user.current_organization.user == current_user || can?(:manage_channel_subscription, current_user.current_organization)
    return render_json(403, I18n.t('controllers.free_subscriptions_controller.errors.no_permissions')) unless current_user.current_organization.enable_free_subscriptions

    channel = current_user.current_organization.channels.find(params[:channel_id])
    if params[:file].present?
      delimiter = ::CsvDelimiter.find(params[:file].path)
      csv_file = CSV.parse(File.read(params[:file].path), headers: true, col_sep: delimiter)
      headers = csv_file.headers
      email_key = headers.detect { |key_name| /email/i.match(key_name) }
      first_name_key = headers.detect { |key_name| /first name/i.match(key_name) }
      last_name_key = headers.detect { |key_name| /last name/i.match(key_name) }

      return render_json(422, I18n.t('controllers.free_subscriptions_controller.errors.invalid_file')) if email_key.blank?

      csv_file.each do |row|
        attrs = row.to_h
        next if attrs[email_key].blank?

        FreeSubscriptions::Create.perform_async(attrs[first_name_key], attrs[last_name_key], attrs[email_key], channel.id, params[:duration_in_months])
      end
    end
    if params[:email].present?
      FreeSubscriptions::Create.perform_async(nil, nil, params[:email], channel.id, params[:duration_in_months])
    end
    head :ok
  end
end
