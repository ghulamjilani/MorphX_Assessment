# frozen_string_literal: true

module Api
  module V1
    module User
      module Feed
        class RecordingsController < Api::V1::ApplicationController
          before_action :authorization_only_for_user

          def index
            query = current_user.purchased_recordings

            query = query.where(channel_id: params[:channel_id]) if params[:channel_id].present?
            query = query.joins(:channel).where(channels: { organization_id: params[:organization_id] }) if params[:organization_id].present?

            @count = query.count
            order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'

            @recordings = query.order('recording_members.created_at': order).limit(@limit).offset(@offset)
          end
        end
      end
    end
  end
end
