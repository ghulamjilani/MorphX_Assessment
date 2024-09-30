# frozen_string_literal: true

module Api
  module V1
    module User
      module Payouts
        class ConnectBankAccountsController < Api::V1::User::ApplicationController
          before_action :set_current_organization
          before_action :check_credentials

          def create
            @payout_method = @current_organization.organizer.payout_methods.find(params[:payout_method_id])
            connect_account = @payout_method.connect_account

            if connect_account.blank?
              return render_json(422, I18n.t('controllers.api.v1.user.payouts.connect_bank_accounts.errors.no_connect_account'))
            end

            stripe_bank_account = Stripe::Account.create_external_account(
              connect_account.account_id,
              {
                external_account: {
                  object: 'bank_account',
                  routing_number: params[:bank_account][:routing_number].presence,
                  account_number: params[:bank_account][:account_number],
                  currency: params[:bank_account][:currency],
                  account_holder_name: params[:bank_account][:account_holder_name],
                  account_holder_type: params[:bank_account][:account_holder_type],
                  country: params[:bank_account][:country]
                }.compact
              }
            )

            StripeDb::ConnectBankAccount.create_or_update_from_stripe(stripe_bank_account.account, stripe_bank_account.id)

            if params[:account_file].present?
              stripe_account_params = {}
              account_file = Stripe::File.create({ file: params[:account_file], purpose: 'account_requirement' })
              stripe_account_params[:documents] = { bank_account_ownership_verification: { files: [account_file.id] } }
              Stripe::Account.update(connect_account.account_id, stripe_account_params)
            end

            if @current_organization.organizer.payout_methods.count == 1
              @payout_method.update(status: :done, is_default: true)
            end

            head 200
          rescue StandardError => e
            render_json(422, e.message)
          end

          def update
            @payout_method = @current_organization.organizer.payout_methods.find(params[:payout_method_id])
            connect_account = @payout_method.connect_account

            if connect_account.blank?
              return render_json(422, I18n.t('controllers.api.v1.user.payouts.connect_bank_accounts.errors.no_connect_account'))
            end

            @connect_bank_account = connect_account.bank_accounts.find(params[:id])

            Stripe::Account.update_external_account(
              connect_account.account_id,
              @connect_bank_account.stripe_id,
              { account_holder_name: params[:bank_account][:account_holder_name] }
            )

            StripeDb::ConnectBankAccount.create_or_update_from_stripe(@connect_bank_account.stripe_account_id, @connect_bank_account.stripe_id)

            if params[:account_file].present?
              stripe_account_params = {}
              account_file = Stripe::File.create({ file: params[:account_file], purpose: 'account_requirement' })
              stripe_account_params[:documents] = { bank_account_ownership_verification: { files: [account_file.id] } }
              Stripe::Account.update(connect_account.account_id, stripe_account_params)
            end

            head 200
          rescue StandardError => e
            render_json(422, e.message)
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
