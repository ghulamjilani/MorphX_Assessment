# frozen_string_literal: true

class Api::V1::User::ReceiptsController < Api::V1::User::ApplicationController
  before_action :set_mailbox
  before_action :set_receipt, only: %i[show update]

  def show
  end

  def update
    @receipt.update(receipt_attributes)
    @receipt.conversation.touch
    render :show
  end

  private

  def set_mailbox
    @mailbox = current_user.mailbox
  end

  def set_receipt
    @receipt = @mailbox.receipts.find(params[:id])
  end

  def receipt_attributes
    params.require(:receipt).permit(:is_read, :trashed, :deleted)
  end
end
