# frozen_string_literal: true

class PaypalController < ActionController::Base
  protect_from_forgery except: [:confirm_purchase]

  # TODO: Create one endpoint to confirm purchase
  # {"payer_email"=>"stdashulya-buyer@icloud.com",
  # "payer_id"=>"U36HAQQYFNDSC",
  # "payer_status"=>"VERIFIED",
  # "first_name"=>"test",
  # "last_name"=>"buyer",
  # "address_name"=>"test buyer",
  # "address_street"=>"1 Main St",
  # "address_city"=>"San Jose",
  # "address_state"=>"CA",
  # "address_country_code"=>"US",
  # "address_zip"=>"95131",
  # "residence_country"=>"US",
  # "txn_id"=>"7DA18256FG739660Y",
  # "mc_currency"=>"USD",
  # "mc_fee"=>"0.39",
  # "mc_gross"=>"2.99",
  # "protection_eligibility"=>"ELIGIBLE",
  # "payment_fee"=>"0.39",
  # "payment_gross"=>"2.99",
  # "payment_status"=>"Completed",
  # "payment_type"=>"instant",
  # "handling_amount"=>"0.00",
  # "shipping"=>"0.00",
  # "tax"=>"0.00",
  # "item_name"=>"Gürhard Bradley Live Session",
  # "item_number"=>"Session::131",
  # "quantity"=>"1",
  # "txn_type"=>"web_accept",
  # "payment_date"=>"2020-10-27T18:43:23Z",
  # "business"=>"stdashulya-facilitator@icloud.com",
  # "receiver_id"=>"E4ZELG6C6Z8SA",
  # "notify_version"=>"UNVERSIONED",
  # "verify_sign"=>"AHJGgoogylgSXthma812sdXYTV0sAI99nx4f-o7D5wF3il0DnVm1njoT",
  # "controller"=>"paypal",
  # "action"=>"confirm_purchase"}
  def confirm_purchase
    @session = Session.find(params[:item_number])
    redirect_to confirm_paypal_purchase_channel_session_path(@session.channel_id, @session.id, type: params[:type],
                                                                                               tx: params[:tx], provider: :paypal, user_id: params[:user_id])
  end
end
