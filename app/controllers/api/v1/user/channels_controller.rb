# frozen_string_literal: true

class Api::V1::User::ChannelsController < Api::V1::ApplicationController
  before_action :set_channel, only: %i[show update destroy]

  def index
    query = current_user.owned_and_invited_channels.not_archived
    query = query.where(status: params[:status]) if params[:status].present? && Channel::Statuses::ALL.include?(params[:status])
    @count = query.count
    order_by = %w[created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'updated_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
    @channels = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
  end

  def show
  end

  def create
    raise 'not implemented'
    unless current_ability.can?(:create_channel_by_business_plan, current_user.current_organization)
      case current_user.service_subscription&.service_status
      when 'active'
        render_json(401, I18n.t('controllers.api.v1.user.channels.business_plan_max_channels_error')) and return
      else
        render_json(401, I18n.t('controllers.api.v1.user.channels.business_plan_limits_error')) and return
      end
    end

    authorize!(:create_channel, current_user.current_organization)
    render :show
  end

  def update
    raise 'not implemented'
    # authorize!(:edit, @channel)
    render :show
  end

  def destroy
    raise 'not implemented'
    # authorize!(:archive, @channel)
    render :show
  end

  private

  def set_channel
    @channel = current_user.channels.friendly.find(id: params[:id])
  end
end
