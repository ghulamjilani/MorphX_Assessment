# frozen_string_literal: true

class PaypalDonationsController < ActionController::Base
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  include LobbiesHelper

  # skip_before_action :verify_authenticity_token, except: [:toggle_donations_amount_visibility, :donations_amount]

  protect_from_forgery except: %i[success_ipn_callback failure_ipn_callback toggle_visibility]

  def toggle_visibility
    @session = Session.find(params[:session_id])

    # NOTE: if you want to convert to authorize! - test it first
    # authorize!(:change_donations_amount_hidden_at, @session)
    raise 'not permitted' unless ::AbilityLib::Legacy::NonAdminCrudAbility.new(current_user).can?(
      :change_donations_amount_hidden_at, @session
    )

    if @session.donations_amount_hidden_at.blank?
      @session.update_attribute(:donations_amount_hidden_at, Time.now)
    else
      @session.update_attribute(:donations_amount_hidden_at, nil)
    end

    head :ok
  end

  def info
    model = params[:abstract_session_type].to_s.constantize.find(params[:abstract_session_id])

    # NOTE: if you want to convert to authorize! - test it first
    raise 'not permitted' unless ::AbilityLib::Legacy::NonAdminCrudAbility.new(current_user).can?(:read, model)

    # authorize!(:read, @session)

    display_amount = true # FIXME

    raised_amount           = nil
    goal_amount             = nil
    goal_reached_in_percent = nil
    raised_by_message       = nil
    contributors            = []

    if display_amount
      raised_amount = number_to_currency(model.total_donations_amount, precision: 2)

      if model.donations_goal.present?
        goal_amount             = number_to_currency(model.donations_goal, precision: 2)
        goal_reached_in_percent = (model.total_donations_amount / model.donations_goal * 100).to_i
      end

      if model.total_donations_amount.to_f.positive?
        raised_by_message = "raised by #{pluralize model.paypal_donations.count, 'contributor'}"
      end

      contributors = model.paypal_donations.collect do |pd|
        { name: pd.user.public_display_name, amount: number_to_currency(pd.additional_data[:payment_gross]) }
      end

      # TODO: what is this?
      if contributors.blank? && [true, false].sample
        contributors = [
          { name: 'fake devuser1', amount: number_to_currency(23.99) },
          { name: 'fake devuser2', amount: number_to_currency(13.99) },
          { name: 'fake devuser3', amount: number_to_currency(123.99) },
          { name: 'fake devuser4', amount: number_to_currency(35.99) },
          { name: 'fake devuser5', amount: number_to_currency(55.99) }
        ]
      end
    end

    result = {
      about_campaign_info: donate_video_tab_content(model),
      display_amount: display_amount,
      goal_amount: goal_amount,
      goal_reached_in_percent: goal_reached_in_percent,
      raised_amount: raised_amount,
      raised_by_message: raised_by_message,
      contributors: contributors
    }

    render json: result
  end

  def success_ipn_callback
    Rails.logger.info request.raw_post.inspect

    case PaypalUtils.validate_and_return(request.raw_post)
    when 'VERIFIED'
      # check that paymentStatus=Completed
      # check that txnId has not been previously processed
      # check that receiverEmail is your Primary PayPal email
      # check that paymentAmount/paymentCurrency are correct
      # process payment

      pd                 = PaypalDonation.new
      pd.payment_status  = request_raw_post_as_hash[:payment_status]
      pd.payer_email     = request_raw_post_as_hash[:payer_email]
      pd.ipn_track_id    = request_raw_post_as_hash[:ipn_track_id]
      pd.additional_data = request_raw_post_as_hash.except(PaypalDonation.new.attributes.symbolize_keys.keys)
      pd.save!
    when 'INVALID'
      # log for investigation
      pd                 = PaypalDonation.find_or_initialize_by(ipn_track_id: request_raw_post_as_hash[:ipn_track_id])
      pd.payment_status  = request_raw_post_as_hash[:payment_status]
      pd.payer_email     = request_raw_post_as_hash[:payer_email]
      pd.ipn_track_id    = request_raw_post_as_hash[:ipn_track_id]
      pd.additional_data = request_raw_post_as_hash.except(PaypalDonation.new.attributes.symbolize_keys.keys)
      pd.save!
    else
      raise
      # error
    end
    # D, [2016-10-22T03:30:56.650605 #30940] DEBUG -- : [173.0.82.126] [7feb5093-87d9-4bfc-a4de-2ce486c5b53d] [qa-portal] [?]   SQL (0.8ms)  INSERT INTO "paypal_donations" ("ipn_track_id", "payment_status", "payer_email", "additional_data", "user_id", "abstract_session_id", "created_at", "updated_at") VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING "id"  [["ipn_track_id", "1d0317ff9aa84"], ["payment_status", "Completed"], ["payer_email", "nfedyashev-buyer@gmail.com"], ["additional_data", "---\n:mc_gross: '10.00'\n:protection_eligibility: Eligible\n:address_status: confirmed\n:payer_id: UFNJKGZRSBAC8\n:tax: '0.00'\n:address_street: 1+Main+St\n:payment_date: 20:30:48+Oct+21,+2016+PDT\n:payment_status: Completed\n:charset: windows-1252\n:address_zip: '95131'\n:first_name: test\n:mc_fee: '0.59'\n:address_country_code: US\n:address_name: test+buyer\n:notify_version: '3.8'\n:custom: ''\n:payer_status: verified\n:business: nfedyashev-facilitator@gmail.com\n:address_country: United+States\n:address_city: San+Jose\n:quantity: '0'\n:verify_sign: AVfSQ5PLCwiNa3zy.rOy.Na-EbloAlJizOXlxLGj5.7Y9jwRozoQD8z8\n:payer_email: nfedyashev-buyer@gmail.com\n:txn_id: 56750079BG672605L\n:payment_type: instant\n:last_name: buyer\n:address_state: CA\n:receiver_email: nfedyashev-facilitator@gmail.com\n:payment_fee: '0.59'\n:receiver_id: GFU5LZSENTKRE\n:txn_type: web_accept\n:item_name: Donation+to+user+Nikita+Fedyashev\n:mc_currency: USD\n:item_number: QxtbUIC3TlZu3sE097Ouy4aJOPs+UN/EqMbLB6r+HTI=\n:residence_country: US\n:test_ipn: '1'\n:transaction_subject: ''\n:payment_gross: '10.00'\n:ipn_track_id: 1d0317ff9aa84\n"], ["user_id", 71], ["abstract_session_id", 196], ["created_at", "2016-10-22 03:30:56.645000"], ["updated_at", "2016-10-22 03:30:56.645000"]]
    # PaypalDonation.last.abstract_session
    #  PaypalDonation Load (1.5ms)  SELECT  "paypal_donations".* FROM "paypal_donations"  ORDER BY "paypal_donations"."id" DESC LIMIT 1
    #  Session Load (2.2ms)  SELECT  "sessions".* FROM "sessions" WHERE "sessions"."id" = $1 LIMIT 1  [["id", 196]]
    # => nil
    # 2.2.2 :002 > PaypalUtils.decrypt_paypal_number PaypalDonation.last.additional_data[:item_number]
    #  PaypalDonation Load (1.2ms)  SELECT  "paypal_donations".* FROM "paypal_donations"  ORDER BY "paypal_donations"."id" DESC LIMIT 1
    # => {:model_class=>"Session", :user_id=>71, :model_id=>196}
    if pd.abstract_session.present?
      payload = { abstract_session_type: pd.abstract_session.class.to_s, abstract_session_id: pd.abstract_session.id }
      PaypalDonationsChannel.broadcast_to pd.abstract_session, { event: :made, data: payload }
    end

    render body: nil
  end

  def failure_ipn_callback
    Rails.logger.info request.env.inspect
    head :ok
  end

  private

  # @return[Hash] example:
  # {"mc_gross" => "1.00",
  #  "protection_eligibility" => "Ineligible",
  #  "address_status" => "confirmed",
  #  "payer_id" => "UFNJKGZRSBAC8",
  #  "tax" => "0.00",
  #  "address_street" => "1+Main+St",
  #  "payment_date" => "13%3A25%3A44+Oct+13%2C+2015+PDT",
  #  "payment_status" => "Pending",
  #  "charset" => "windows-1252",
  #  "address_zip" => "95131",
  #  "first_name" => "test",
  #  "mc_fee" => "0.33",
  #  "address_country_code" => "US",
  #  "address_name" => "test+buyer",
  #  "notify_version" => "3.8",
  #  "custom" => "",
  #  "payer_status" => "verified",
  #  "business" => "nfedyashev-facilitator@gmail.com",
  #  "address_country" => "United+States",
  #  "address_city" => "San+Jose",
  #  "quantity" => "0",
  #  "verify_sign" => "ADvj-tIuMJxr3YEo-QPTwZC-2h.3AkEVqresFBoggpJR2C3t100V3tQD",
  #  "payer_email" => "nfedyashev-buyer@gmail.com",
  #  "txn_id" => "6BK486076P3244908",
  #  "payment_type" => "instant",
  #  "last_name" => "buyer",
  #  "address_state" => "CA",
  #  "receiver_email" => "nfedyashev-facilitator@gmail.com",
  #  "payment_fee" => "0.33",
  #  "receiver_id" => "GFU5LZSENTKRE",
  #  "pending_reason" => "paymentreview",
  #  "txn_type" => "web_accept",
  #  "item_name" => "My+Donation",
  #  "mc_currency" => "USD",
  #  "item_number" => "",
  #  "residence_country" => "US",
  #  "test_ipn" => "1",
  #  "transaction_subject" => "",
  #  "payment_gross" => "1.00",
  #  "ipn_track_id" => "cc3575d626d9b"}
  def request_raw_post_as_hash
    @request_raw_post_as_hash ||= request
                                  .raw_post
                                  .dup
                                  .tap { |string| string.gsub!("==\n", ''); string.gsub!("=\n", '') }
                                  .split('&')
                                  .map { |i| (i.split('=').length == 2) ? i.split('=') : i.split('=') + [''] }
                                  .to_h
                                  .symbolize_keys
                                  .map { |k, v| [k, CGI.unescape(v)] }
                                  .to_h
  end
end
