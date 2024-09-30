# frozen_string_literal: true

class Api::V1::User::FfmpegserviceAccountsController < Api::V1::User::ApplicationController
  before_action :set_ffmpegservice_account, only: %i[show update destroy]
  before_action :credential_for_current_organization

  def index
    query = current_organization.ffmpegservice_accounts

    if params[:current_service].present?
      current_service = params[:current_service].split(',')
      query = query.where(current_service: current_service)
    end

    query = query.joins(studio_room: :studio).preload(studio_room: :studio) if params[:studio_id].present? || params[:studio_room_id].present?

    query = query.where(studios: { id: params[:studio_id] }) if params[:studio_id].present?
    if params[:studio_room_id].present?
      query = query.where(studio_room_id: params[:studio_room_id]) if params[:studio_room_id] != '0'
      query = query.where(studio_room_id: nil) if params[:studio_room_id] == '0'
    end

    @count = query.count

    order_by = %w[id custom_name created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'created_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
    @ffmpegservice_accounts = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset).preload(:studio_room)
  end

  def show
  end

  def new
    wa_params = {
      organization_id: nil,
      delivery_method: delivery_method_param,
      transcoder_type: (current_organization.ffmpegservice_transcode ? 'transcoded' : 'passthrough'),
      reserved_by_id: current_organization.id,
      reserved_by_type: current_organization.class.name.to_s
    }

    @ffmpegservice_account = FfmpegserviceAccount.order('sandbox asc').find_by(wa_params)

    unless @ffmpegservice_account
      wa_params = wa_params.merge({
                                    reserved_by_id: nil,
                                    reserved_by_type: nil
                                  })
      @ffmpegservice_account = FfmpegserviceAccount.order('sandbox asc').find_by(wa_params)
    end

    render_json(404, 'No more unused ffmpegservice accounts left') and return unless @ffmpegservice_account

    @ffmpegservice_account.reserved_by_id = current_organization.id
    @ffmpegservice_account.reserved_by_type = current_organization.class.to_s
    @ffmpegservice_account.studio_room_id = nil
    @ffmpegservice_account.save!

    render :show
  end

  def create
    @ffmpegservice_account = current_organization.reserved_ffmpegservice_accounts.find(params[:id])
    @ffmpegservice_account.attributes = create_ffmpegservice_account_params
    @ffmpegservice_account.reserved_by_id = nil
    @ffmpegservice_account.reserved_by_type = nil
    @ffmpegservice_account.organization_id = current_organization.id
    @ffmpegservice_account.user_id = current_user.id if params[:current_service] == 'main'
    @ffmpegservice_account.save!

    render :show
  end

  def update
    @ffmpegservice_account.update!(update_ffmpegservice_account_params)
    render :show
  end

  def destroy
    @ffmpegservice_account.nullify!
    render :show
  end

  def get_status
    wa_client = Sender::Ffmpegservice.client(account: @ffmpegservice_account)
    # render_json(200, "started") # local test
    render_json(200, wa_client.state_stream[:state])
  rescue StandardError
    render_json(422, 'Error during WA state check')
  end

  private

  def current_organization
    @current_organization ||= current_user.current_organization
  end

  def credential_for_current_organization
    render_json 401, 'Only user with multiroom credential can get access here' unless can?(:multiroom_config,
                                                                                           current_organization)
  end

  def set_ffmpegservice_account
    @ffmpegservice_account = current_organization.ffmpegservice_accounts.find(params[:id])
  end

  def delivery_method_param
    delivery_method = params.require(:delivery_method)
    raise 'delivery_method value is not included in the list: "pull", "push"' unless %w[pull
                                                                                        push].include? delivery_method

    delivery_method
  end

  def create_ffmpegservice_account_params
    params.require(%i[custom_name current_service])
    params.permit(
      :custom_name,
      :current_service,
      :source_url,
      :studio_room_id
    )
  end

  def update_ffmpegservice_account_params
    params.permit(
      :custom_name,
      :source_url,
      :studio_room_id
    )
  end
end
