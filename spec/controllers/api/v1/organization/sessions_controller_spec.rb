# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::Organization::SessionsController do
  let(:session) { create(:session_with_livestream_only_delivery) }
  let(:channel) { session.channel }
  let(:current_organization) { channel.organization }
  let(:organization_membership) do
    create(:organization_membership, organization_id: current_organization.id,
                                     role: OrganizationMembership::Roles::PRESENTER)
  end
  let(:zoom_identity) { create(:zoom_identity, user: organization_membership.user) }
  let(:user) { zoom_identity.user }
  let(:wa) { create(:ffmpegservice_account, organization_id: current_organization.id, user_id: user.id) }
  let(:auth_header_value) { "Bearer #{JwtAuth.organization(current_organization)}" }
  let(:zoom_user) do
    {
      custom_attributes: [
        {
          key: 'cb3674544gexq',
          name: 'Country of Citizenship',
          value: 'Nepal'
        }
      ],
      id: 'z8dsdsdsdsdCfp8uQ',
      first_name: 'Harry',
      last_name: 'Grande',
      email: 'harryg@dfkjdslfjkdsfjkdsf.fsdfdfd',
      type: 2,
      role_name: 'Owner',
      pmi: 0o00000000,
      use_pmi: false,
      personal_meeting_url: 'https://zoom.us/j/6352635623323434343443',
      timezone: 'America/Los_Angeles',
      verified: 1,
      dept: '',
      created_at: '2018-11-15T01:10:08Z',
      last_login_time: '2019-09-13T21:08:52Z',
      last_client_version: '4.4.55383.0716(android)',
      pic_url: 'https://lh4.googleusercontent.com/-hsgfhdgsfghdsfghfd-photo.jpg',
      host_key: '0000',
      jid: 'hghghfghdfghdfhgh@xmpp.zoom.us',
      group_ids: [],
      im_group_ids: ['CcSAAAAAAABBBVoQ'],
      account_id: 'EAAAAAbbbbbCCCCHMA',
      language: 'en-US',
      phone_country: 'USA',
      phone_number: '00000000',
      status: 'active',
      role_id: 'hdsfwyteg3675hgfs'
    }.to_json
  end

  render_views

  before do
    stub_request(:any, %r{.*zoom.us/v2/users/*})
      .to_return(status: 200, body: zoom_user, headers: {})
  end

  describe '.json request format' do
    describe 'GET index:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :index, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        before do
          request.headers['Authorization'] = auth_header_value
        end

        before do
          get :index, params: {}, format: :json
        end

        it { expect(response).to be_successful }
        it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
      end
    end

    describe 'GET show:' do
      context 'when JWT missing' do
        it 'returns 401' do
          get :show, params: { id: session.id }, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when JWT present' do
        context 'when user exists' do
          before do
            request.headers['Authorization'] = auth_header_value
            get :show, params: { id: session.id }, format: :json
          end

          it { expect(response).to be_successful }
          it { expect { JSON.parse(response.body) }.not_to raise_error, response.body }
        end
      end
    end

    describe 'POST create:' do
      let(:ffmpegservice_account_id) { create(:ffmpegservice_account).id }
      let(:valid_params) do
        service_type = Room::ServiceTypes::ALL.sample
        device_types = {
          webrtcservice: 'desktop_basic',
          rtmp: 'studio_equipment',
          mobile: 'mobile',
          ipcam: 'ipcam',
          zoom: 'zoom',
          webrtc: 'webrtc'
        }
        valid_params = {
          user_id: user.id,
          channel_id: channel.id,
          session: {
            title: "#{Forgery::Name.company_name} #{channel.title} session",
            description: Forgery(:lorem_ipsum).words(10),
            record: [true, false].sample,
            allow_chat: [true, false].sample,
            duration: (15..180).step(5).to_a.sample,
            pre_time: (0..30).step(5).to_a.sample,
            autostart: [true, false].sample,
            device_type: device_types[service_type.to_sym],
            service_type: service_type,
            start_at: ((0..89).to_a.sample.days.from_now + (1...(60 * 24)).step(10).to_a.sample.minutes).strftime('%Y-%m-%d %H:%M:%S %z'),
            channel_id: channel.id
          }
        }
        valid_params[:session][:ffmpegservice_account_id] = ffmpegservice_account_id if [Room::ServiceTypes::IPCAM,
                                                                         Room::ServiceTypes::RTMP].include?(service_type)
        valid_params
      end

      context 'when JWT missing' do
        it 'returns 401' do
          post :create, params: valid_params, format: :json
          expect(response).to have_http_status :unauthorized
        end
      end

      # FIXME: randomly failed
      # context 'when JWT present' do
      #   before do
      #     request.headers['Authorization'] = auth_header_value
      #   end
      #
      #   it 'creates new session' do
      #     expect do
      #       post :create, params: valid_params, format: :json
      #     end.to change(Session, :count).by(1)
      #   end
      # end
    end
  end
end
