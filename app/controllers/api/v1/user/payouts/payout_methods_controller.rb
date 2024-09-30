# frozen_string_literal: true

module Api
  module V1
    module User
      module Payouts
        class PayoutMethodsController < Api::V1::User::ApplicationController
          before_action :set_current_organization
          before_action :check_credentials

          def index
            query = @current_organization.organizer.payout_methods.order(created_at: :desc)
            @count = query.count
            @payout_methods = query.limit(@limit).offset(@offset)
          end

          def show
            @payout_method = @current_organization.organizer.payout_methods.includes(connect_account: :bank_accounts).find(params[:id])
          end

          def create
            @payout_method = @current_organization.organizer.payout_methods.create(
              business_type: params[:payout_method][:business_type],
              provider: params[:payout_method][:provider],
              country: params[:payout_method][:country],
              status: :draft
            )
            render :show
          end

          def update
            @payout_method = @current_organization.organizer.payout_methods.find(params[:id])

            if [true, 'true', 1, '1'].include?(params[:default])
              @current_organization.organizer.payout_methods.update_all(is_default: false)
              @payout_method.update(is_default: true)
            end

            case @payout_method.provider
            when 'stripe'
              if [true, 'true', 1, '1'].include?(params[:accept_tos])
                @connect_account = @payout_method.connect_account&.stripe_item

                if @connect_account.blank?
                  return render_json(422, I18n.t('controllers.api.v1.user.payouts.payout_methods.errors.no_connect_account'))
                end

                stripe_account_params = { tos_acceptance: { date: Time.now.to_i, ip: request.remote_ip, user_agent: request.user_agent } }
                Stripe::Account.update(@connect_account.id, stripe_account_params)
              end
            else
              raise 'Not Implemented'
            end

            render :show
          end

          def destroy
            @payout_method = @current_organization.organizer.payout_methods.find(params[:id])

            if @payout_method.pid.blank?
              @payout_method.destroy
              head 200 and return
            end

            case @payout_method.provider
            when 'stripe'
              @connect_account = @payout_method.connect_account
              Stripe::Account.delete(@connect_account.account_id) if @connect_account.present?
              @current_organization.organizer.payout_methods.first&.update(is_default: true) if @payout_method.is_default?
              @payout_method.destroy
            else
              raise 'Not Implemented'
            end
            head 200
          end

          private

          def current_ability
            @current_ability ||= ::AbilityLib::OrganizationAbility.new(current_user)
          end

          def check_credentials
            authorize!(:manage_payment_method, @current_organization)
          end

          def set_current_organization
            @current_organization = current_user.current_organization
          end
        end
      end
    end
  end
end
