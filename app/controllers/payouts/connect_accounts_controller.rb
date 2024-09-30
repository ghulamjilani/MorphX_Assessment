# frozen_string_literal: true

class Payouts::ConnectAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_current_organization
  before_action :check_credentials

  def create
    @payout_method = @user.payout_methods.find(params[:payout_method_id])

    dob = Date.strptime(account_params[:date_of_birth], '%m/%d/%Y')
    phone = "+#{Phonelib.parse(account_params[:phone]).sanitized}"

    payout_identity = @payout_method.payout_identity || @payout_method.build_payout_identity

    stripe_account_params = {
      email: account_params[:email],
      requested_capabilities: %w[transfers card_payments],
      business_profile: {
        url: account_params[:business_website] || @user.absolute_path,
        mcc: account_params[:mcc]
      },
      individual: {
        first_name: account_params[:first_name],
        last_name: account_params[:last_name],
        dob: {
          day: dob.day,
          month: dob.month,
          year: dob.year
        },
        email: account_params[:email],
        ssn_last_4: account_params[:ssn_last_4], # rubocop:disable Naming/VariableNumber
        phone: phone,
        address: {
          line1: account_params[:address_line_1], # rubocop:disable Naming/VariableNumber
          line2: account_params[:address_line_2], # rubocop:disable Naming/VariableNumber
          city: account_params[:city],
          state: account_params[:state],
          postal_code: account_params[:zip],
          country: account_params[:country]
        }
      },
      type: 'custom',
      country: account_params[:country],
      business_type: @payout_method.business_type,
      # Terms of service acceptance
      tos_acceptance: { date: Time.now.to_i, ip: request.remote_ip, user_agent: request.user_agent }
    }

    # process uploaded document
    if params[:passport_file].present?
      passport_file = Stripe::File.create({ file: params[:passport_file], purpose: 'identity_document' })
      stripe_account_params[:individual][:verification] = { document: { front: passport_file.id } }
    end
    if params[:additional_document_file].present?
      additional_document_file = Stripe::File.create({ file: params[:additional_document_file], purpose: 'identity_document' })
      stripe_account_params[:individual][:verification] = { additional_document: { front: additional_document_file.id } }
    end

    stripe_connect_account = Stripe::Account.create(stripe_account_params)
    @payout_method.update(pid: stripe_connect_account.id)
    @connect_account = StripeDb::ConnectAccount.create(user_id: @user.id, account_id: stripe_connect_account.id)

    # Just store all user info, visible in service_admin_panel
    payout_identity.attributes = {
      first_name: account_params[:first_name],
      last_name: account_params[:last_name],
      date_of_birth: dob,
      email: account_params[:email],
      ssn_last_4: account_params[:ssn_last_4], # rubocop:disable Naming/VariableNumber
      phone: phone,
      address_line_1: account_params[:address_line_1], # rubocop:disable Naming/VariableNumber
      address_line_2: account_params[:address_line_2], # rubocop:disable Naming/VariableNumber
      city: account_params[:city],
      state: account_params[:state],
      zip: account_params[:zip]
    }
    payout_identity.save
  rescue StandardError => e
    render json: e.message, status: 422
  end

  def update
    @payout_method = @user.payout_methods.find(params[:payout_method_id])
    @connect_account = @payout_method.connect_account

    dob = Date.strptime(account_params[:date_of_birth], '%m/%d/%Y')
    phone = "+#{Phonelib.parse(account_params[:phone]).sanitized}"
    payout_identity = @payout_method.payout_identity || @payout_method.build_payout_identity

    stripe_account_params = {
      email: account_params[:email],
      requested_capabilities: %w[transfers card_payments],
      business_profile: {
        url: account_params[:business_website] || @user.absolute_path,
        mcc: account_params[:mcc]
      },
      individual: {
        first_name: account_params[:first_name],
        last_name: account_params[:last_name],
        dob: {
          day: dob.day,
          month: dob.month,
          year: dob.year
        },
        email: account_params[:email],
        ssn_last_4: account_params[:ssn_last_4], # rubocop:disable Naming/VariableNumber
        phone: phone,
        address: {
          line1: account_params[:address_line_1], # rubocop:disable Naming/VariableNumber
          line2: account_params[:address_line_2], # rubocop:disable Naming/VariableNumber
          city: account_params[:city],
          state: account_params[:state],
          postal_code: account_params[:zip],
          country: account_params[:country]
        }
      },
      tos_acceptance: { date: Time.now.to_i, ip: request.remote_ip, user_agent: request.user_agent }
    }

    if params[:passport_file].present?
      passport_file = Stripe::File.create({ file: params[:passport_file], purpose: 'identity_document' })
      stripe_account_params[:individual][:verification] = { document: { front: passport_file.id } }
    end
    if params[:additional_document_file].present?
      additional_document_file = Stripe::File.create({ file: params[:additional_document_file], purpose: 'identity_document' })
      stripe_account_params[:individual][:verification] = { additional_document: { front: additional_document_file.id } }
    end

    Stripe::Account.update(@connect_account.account_id, stripe_account_params)

    # Just store all user info, visible in service_admin_panel
    payout_identity.attributes = {
      first_name: account_params[:first_name],
      last_name: account_params[:last_name],
      date_of_birth: dob,
      email: account_params[:email],
      ssn_last_4: account_params[:ssn_last_4], # rubocop:disable Naming/VariableNumber
      phone: phone,
      address_line_1: account_params[:address_line_1], # rubocop:disable Naming/VariableNumber
      address_line_2: account_params[:address_line_2], # rubocop:disable Naming/VariableNumber
      city: account_params[:city],
      state: account_params[:state],
      zip: account_params[:zip]
    }
    payout_identity.save
    @connect_bank_account = @payout_method.connect_account.bank_accounts.first
  rescue StandardError => e
    render json: e.message, status: 422
  end

  private

  def account_params
    @account_params ||= params.require(:account_info).permit!
  end

  def current_ability
    @current_ability ||= ::AbilityLib::OrganizationAbility.new(current_user)
  end

  def check_credentials
    authorize!(:manage_payment_method, @current_organization)
  end

  def set_current_organization
    @current_organization = @organization = current_user&.current_organization
    @user = @current_organization&.organizer
  end
end
