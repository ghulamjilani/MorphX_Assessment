# frozen_string_literal: true

require 'spec_helper'

describe PaypalDonationsController do
  describe 'POST :success_callback' do
    context 'when given INVALID parse results' do
      it 'is saved anyways' do
        allow(PaypalUtils).to receive(:validate_and_return).and_return('INVALID')

        post :success_ipn_callback,
             body: 'mc_gross=1.00&protection_eligibility=Ineligible&address_status=confirmed&payer_id=UFNJKGZRSBAC8&tax=0.00
                    &address_street=1+Main+St&payment_date=13%3A25%3A44+Oct+13%2C+2015+PDT&payment_status=Pending&charset=windows-1252
                    &address_zip=95131&first_name=test&mc_fee=0.33&address_country_code=US&address_name=test+buyer&notify_version=3.8&custom=
                    &payer_status=verified&business=nfedyashev-facilitator%40gmail.com&address_country=United+States&address_city=San+Jose&quantity=0
                    &verify_sign=ADvj-tIuMJxr3YEo-QPTwZC-2h.3AkEVqresFBoggpJR2C3t100V3tQD&payer_email=nfedyashev-buyer%40gmail.com&txn_id=6BK486076P3244908
                    &payment_type=instant&last_name=buyer&address_state=CA&receiver_email=nfedyashev-facilitator%40gmail.com&payment_fee=0.33
                    &receiver_id=GFU5LZSENTKRE&pending_reason=paymentreview&txn_type=web_accept&item_name=My+Donation&mc_currency=USD&item_number=
                    &residence_country=US&test_ipn=1&transaction_subject=&payment_gross=1.00&ipn_track_id=cc3575d626d9b'

        expect(response).to be_successful
        expect(PaypalDonation.count).to eq(1)
      end
    end

    context 'when given VERIFIED parse results' do
      it 'is saved with all corresponding parameters' do
        livestream_session = create(:livestream_session)
        user1 = create(:user)
        allow(PaypalUtils).to receive(:validate_and_return).and_return('VERIFIED')

        item_number = PaypalUtils.paypal_number(user_id: user1.id, abstract_session: livestream_session)

        # {"mc_gross"=>"10.00", "protection_eligibility"=>"Eligible", "address_status"=>"confirmed", "payer_id"=>"UFNJKGZRSBAC8", "tax"=>"0.00", "address_street"=>"1
        #   Main St", "payment_date"=>"04:37:51 Nov 15, 2016 PST", "payment_status"=>"Completed", "charset"=>"windows-1252", "address_zip"=>"95131", "first_name"=>"test",
        #   "mc_fee"=>"0.59", "address_country_code"=>"US", "address_name"=>"test buyer", "notify_version"=>"3.8", "custom"=>"", "payer_status"=>"verified", "business"=>"nfedyashev-facilitator@gmail.com",
        #   "address_country"=>"United States", "address_city"=>"San Jose", "quantity"=>"0", "verify_sign"=>"AE8ZuhFUR7Zsh0.vEL9Ies2oeMy1Ae7UEvHVKb5hbUY5AL5AeoHYyyTm",
        #   "payer_email"=>"nfedyashev-buyer@gmail.com", "txn_id"=>"1GH38138PU372110S", "payment_type"=>"instant", "last_name"=>"buyer", "address_state"=>"CA",
        #    "receiver_email"=>"nfedyashev-facilitator@gmail.com", "payment_fee"=>"0.59", "receiver_id"=>"GFU5LZSENTKRE", "txn_type"=>"web_accept", "item_name"=>"Tip to user Patrick Crawford",
        #   "mc_currency"=>"USD", "item_number"=>"iQ2JLGeiATgZN3UzW+x0FL9cTg8b6Txde5DAurdUoI0=", "residence_country"=>"US", "test_ipn"=>"1", "transaction_subject"=>"", "payment_gross"=>"10.00",
        #   "ipn_track_id"=>"46ded592f51"}
        post :success_ipn_callback,
             body: "mc_gross=1.00&protection_eligibility=Ineligible&address_status=confirmed&payer_id=UFNJKGZRSBAC8&tax=0.00
                    &address_street=1+Main+St&payment_date=13%3A25%3A44+Oct+13%2C+2015+PDT&payment_status=Pending&charset=windows-1252&address_zip=95131
                    &first_name=test&mc_fee=0.33&address_country_code=US&address_name=test+buyer&notify_version=3.8&custom=&payer_status=verified
                    &business=nfedyashev-facilitator%40gmail.com&address_country=United+States&address_city=San+Jose&quantity=0
                    &verify_sign=ADvj-tIuMJxr3YEo-QPTwZC-2h.3AkEVqresFBoggpJR2C3t100V3tQD&payer_email=nfedyashev-buyer%40gmail.com&txn_id=6BK486076P3244908
                    &payment_type=instant&last_name=buyer&address_state=CA&receiver_email=nfedyashev-facilitator%40gmail.com&payment_fee=0.33
                    &receiver_id=GFU5LZSENTKRE&pending_reason=paymentreview&txn_type=web_accept&item_name=My+Donation&mc_currency=USD&item_number=#{item_number}
                    &residence_country=US&test_ipn=1&transaction_subject=&payment_gross=1.00&ipn_track_id=cc3575d626d9b"

        expect(response).to be_successful
        expect(PaypalDonation.count).to eq(1)
        expect(PaypalDonation.last.abstract_session).to eq(livestream_session)
        expect(PaypalDonation.last.user).to eq(user1)
      end
    end
  end

  describe 'POST :failure_callback' do
    it 'works' do
      post :failure_ipn_callback, params: { param1: 'val' }
      expect(response).to be_successful
    end
  end

  describe 'GET :info' do
    let(:session) do
      create(:immersive_session,
             donations_goal: 300,
             donate_video_tab_options_in_csv_format: '1,5,10',
             donate_video_tab_content_in_markdown_format: 'Visit our [kickstarter campaign](https://www.kickstarter.com/projects/1523379957/oculus-rift-step-into-the-game)')
    end
    let(:current_user) { session.organizer }

    before do
      sign_in current_user, scope: :user
      create(:paypal_donation, abstract_session: session)
      create(:paypal_donation, abstract_session: session)
    end

    it 'works' do
      get :info, params: { abstract_session_id: session.id, abstract_session_type: 'Session' }
      expect do
        JSON.parse(response.body)
      end.not_to raise_error
    end
  end

  describe 'POST :toggle_visibility' do
    let(:session) { create(:immersive_session) }
    let(:current_user) { session.organizer }

    before do
      sign_in current_user, scope: :user

      expect(session.reload.donations_amount_hidden_at).to be_blank
    end

    it 'works' do
      post :toggle_visibility, params: { session_id: session.id }
      expect(response).to be_successful
      expect(session.reload.donations_amount_hidden_at).to be_present

      post :toggle_visibility, params: { session_id: session.id }
      expect(response).to be_successful
      expect(session.reload.donations_amount_hidden_at).to be_blank
    end
  end
end
