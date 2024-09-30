# frozen_string_literal: true

module Api
  module Invitations
    class ChannelsController < Api::ApplicationController
      before_action :load_channel, only: %i[accept reject]

      # curl -XGET http://localhost:3000/api_portal/channels/1/videos/ -H 'X-User-Token: 9f3f5ab404dde17472119127b52aeadb1' -H 'X-User-ID:1'
      def index
        @invites = ChannelInvitedPresentership.joins(:channel).where(presenter: current_user.presenter).pending
      rescue StandardError => e
        render_json(500, e.message, e)
      end

      def accept
        @presentership.accept!
        render_json(200, 'success')
      end

      def reject
        @presentership.reject!
        render_json(200, 'success')
      end

      private

      def load_channel
        @channel = Channel.find(params[:id])
        @presentership = ChannelInvitedPresentership.where(channel: @channel,
                                                           presenter: current_user.presenter).pending.first!
        current_user.touch
      end
    end
  end
end
