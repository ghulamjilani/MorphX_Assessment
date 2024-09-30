# frozen_string_literal: true

class Api::V1::Public::UserAccountsController < Api::V1::Public::ApplicationController
  before_action :set_user_account, only: [:show]

  def show
  end

  private

  def set_user_account
    @user_account = UserAccount.find(params[:id])
  end
end
