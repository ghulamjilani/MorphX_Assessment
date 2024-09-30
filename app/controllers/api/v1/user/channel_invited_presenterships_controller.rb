# frozen_string_literal: true

module Api
  module V1
    module User
      class ChannelInvitedPresentershipsController < Api::V1::User::ApplicationController
        def index
          current_user.create_presenter! if current_user.presenter.blank?

          query = current_user.presenter.channel_invited_presenterships
          query = query.where(status: params[:status]) if params[:status].present?
          query = query.where(channel_id: params[:channel_id]) if params[:channel_id].present?

          order_by = if %w[created_at updated_at invitation_sent_at
                           status].include?(params[:order_by])
                       params[:order_by]
                     else
                       'invitation_sent_at'
                     end
          order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
          @channel_invited_presenterships = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
        end

        def show
          @channel_invited_presentership = current_user.presenter.channel_invited_presenterships.find(params[:id])
        end

        def update
          @channel_invited_presentership = current_user.presenter.channel_invited_presenterships.pending.find(params[:id])
          current_user.touch if @channel_invited_presentership.update(update_channel_invited_presentership_params)
          @channel_invited_presentership.reload

          render :show
        end

        private

        def update_channel_invited_presentership_params
          params.permit(:status).tap do |attributes|
            attributes.delete(:status) unless [ChannelInvitedPresentership::Statuses::ACCEPTED,
                                               ChannelInvitedPresentership::Statuses::REJECTED].include?(attributes[:status])
          end
        end
      end
    end
  end
end
