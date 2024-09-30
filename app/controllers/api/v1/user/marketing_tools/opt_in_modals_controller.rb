# frozen_string_literal: true

module Api
  module V1
    module User
      module MarketingTools
        class OptInModalsController < Api::V1::User::MarketingTools::ApplicationController
          before_action :modal, only: %i[show update destroy]

          def index
            raise AccessForbiddenError unless current_ability.can?(:create, ::MarketingTools::OptInModal)

            query = ::MarketingTools::OptInModal.joins(:channel)

            if params[:model_type].present? && params[:model_id].present?
              model_type = params[:model_type].capitalize
              channel = case model_type
                        when 'Channel'
                          Channel.find(params[:model_id])
                        when 'Video', 'Recording', 'Session'
                          model_type.constantize.find(params[:model_id]).channel
                        else
                          raise 'Invalid Model Type'
                        end

              raise AccessForbiddenError unless current_ability.can?(:manage_opt_in_modals, channel)

              query = query.where(channel_uuid: channel.uuid)
            else
              query = query.where(channel_uuid: current_user.owned_and_invited_channels.not_archived.pluck(:uuid))
            end

            query = query.where(active: params[:active]) if params[:active].present?
            @count = query.count

            order_by = if %w[title created_at].include?(params[:order_by])
                         params[:order_by]
                       else
                         'title'
                       end
            order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
            @modals = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
          end

          def show
          end

          def create
            channel = Channel.find_by!(uuid: params[:channel_uuid])
            raise AccessForbiddenError if current_ability.cannot?(:create, ::MarketingTools::OptInModal) ||
                                          current_ability.cannot?(:manage_opt_in_modals, channel)

            @modal = ::MarketingTools::OptInModal.create(modal_params)
            render :show
          end

          def update
            raise AccessForbiddenError if current_ability.cannot?(:edit, ::MarketingTools::OptInModal) ||
                                          current_ability.cannot?(:manage_opt_in_modals, @modal.channel)

            @modal.update(modal_params)
            render :show
          end

          def destroy
            raise AccessForbiddenError if current_ability.cannot?(:edit, ::MarketingTools::OptInModal) ||
                                          current_ability.cannot?(:manage_opt_in_modals, @modal.channel)

            @modal.destroy!
            head 200
          end

          private

          def modal
            @modal ||= ::MarketingTools::OptInModal.find(params[:id])
          end

          def current_ability
            @current_ability ||= AbilityLib::MarketingTools::OptInModalAbility.new(current_user).merge(AbilityLib::ChannelAbility.new(current_user))
          end

          def modal_params
            params.permit(
              :title,
              :description,
              :channel_uuid,
              :active,
              :trigger_time,
              system_template_attributes: %i[body name]
            )
          end
        end
      end
    end
  end
end
