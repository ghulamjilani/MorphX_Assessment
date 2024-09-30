# frozen_string_literal: true

class BecomePresenter::SaveChannelInfo
  def initialize(user, channel_params)
    @user = user
    @channel_params = channel_params
    @errors = []
  end

  def execute
    return false if @channel_params.blank?

    @channel = get_channel
    return false unless @channel

    # Force channel association with company if it exists
    # As Alex said, if user wants to have personal(without company) account
    # then he can use another email and create new account
    @channel.attributes = @channel_params
    @channel.status = :approved
    @channel.is_default = true
    if @channel.save
      @channel.list!
      true
    else
      Rails.logger.debug errors
      false
    end
  end

  attr_reader :channel

  def errors
    @errors << @channel.errors.full_messages if @channel && @channel.errors.present?
    @errors.flatten.compact.uniq.join('. ')
  end

  def get_channel
    channel = Channel.find(@channel_params.delete(:id)) if @channel_params[:id]
    @user.create_presenter if @user.organization.blank? && @user.presenter.blank?
    if channel
      if (@user.organization && channel.organization_id && (channel.organization_id != @user.organization.id)) ||
         (@user.presenter && channel.presenter_id && (channel.presenter_id != @user.presenter.id))
        @errors << 'Unauthorised.'
        return false
      end
      if @user.organization
        channel.organization_id = @user.organization.id
        channel.presenter_id = nil
      else
        channel.presenter_id = @user.presenter.id
        channel.organization_id = nil
      end
    else
      channel = if @user.organization
                  @user.organization.channels.build
                else
                  @user.presenter.channels.build
                end
    end
    channel
  end

  private

  def create_organization
    @user.build_organization(name: '').save!
  end
end
