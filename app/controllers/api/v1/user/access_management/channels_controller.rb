# frozen_string_literal: true

module Api
  module V1
    module User
      module AccessManagement
        class ChannelsController < Api::V1::User::AccessManagement::ApplicationController
          # For eg we use it for list of channels for blog form
          def index
            return unless current_user.current_organization

            if current_user == current_user.current_organization.user
              @channels = current_user.current_organization.channels.approved.not_archived
            else
              @channels = current_user.organization_channels_with_credentials(current_user.current_organization, params[:permission_code]).approved.not_archived
            end
            @count = @channels.count
            @channels = @channels.order(title: :asc).limit(@limit).offset(@offset)
          end
        end
      end
    end
  end
end
