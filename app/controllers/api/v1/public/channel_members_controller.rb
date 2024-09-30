# frozen_string_literal: true

class Api::V1::Public::ChannelMembersController < Api::V1::Public::ApplicationController
  before_action :set_channel

  def index
    scope = params[:scope] || 'presenters'
    codes = case scope
            when 'presenters'
              %i[end_session start_session]
            when 'blog'
              %i[manage_blog_post]
            else
              []
            end
    @channel_members = OrganizationMembership.for_channel_by_credential(@channel.id, codes, @limit, @offset)
  end

  private

  def set_channel
    @channel = Channel.find(params[:channel_id])
  end
end
