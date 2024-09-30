# frozen_string_literal: true

require 'spec_helper'

describe ChannelsController do
  render_views

  before do
    sign_in current_user, scope: :user
  end

  describe 'PUT :you_may_also_like_visibility' do
    let!(:channel) { create(:channel) }
    let(:current_user) { channel.organizer }

    it 'works' do
      expect(channel.you_may_also_like_is_visible).to be true
      put :you_may_also_like_visibility, params: { id: channel.slug, value: Channel::Constants::YouMayAlsoLike::HIDDEN }

      expect(response).to be_successful
      expect(channel.reload.you_may_also_like_is_visible).to be false
    end
  end

  describe 'POST :request_session' do
    render_views
    before { sign_in(current_user, scope: :user) }

    let(:current_user) { create(:user) }
    let!(:channel) { create(:channel) }

    context 'when given valid request params' do
      it 'notifies about requested different time ' do
        valid_params = { date: '23 February 2018',
                         requested_at: '16:15',
                         delivery_method: 'livestream',
                         comment: 'zz' }

        post :request_session, params: {
          id: channel.id,
          **valid_params.tap do |params|
            # has to work in all cases(notify with what we have)
            params.delete(:delivery_method) if [true, false].sample

            params.delete(:immersive_type) if [true, false].sample
          end
        }, format: :js

        expect(response).to be_successful
        expect(flash.now[:success]).to be_present
      end
    end
  end

  describe 'PUT :notify_me' do
    let(:current_user) { create(:organization).user }
    let(:channel) { create(:channel) }

    it 'tracks notification request' do
      expect(UpcomingChannelNotificationMembership.count).to eq(0)

      put :notify_me, params: { id: channel.id }, format: :js

      expect(response).to be_successful
      expect(UpcomingChannelNotificationMembership.count).to eq(1)
    end
  end

  describe 'POST :archive' do
    let(:current_user) { channel.organizer }
    let(:session) { create(:immersive_session) }
    let(:channel) { session.channel }

    it 'archives' do
      session.start_at = 2.days.ago.beginning_of_hour
      session.save(validate: false)

      expect(Session.archived_session_ids).to eq([])

      expect(channel.archived?).to eq(false)

      @request.env['HTTP_REFERER'] = 'http://localhost:3000/whatever'
      post :archive, params: { id: channel.id }

      expect(response).to redirect_to('http://localhost:3000/whatever')
      expect(channel.reload.archived?).to eq(true)
      expect(Session.archived_session_ids).to eq([session.id])
    end
  end

  describe 'POST :create' do
    let(:current_user) { create(:organization_with_subscription).user }

    let(:valid_params) do
      {
        category_id: create(:channel_category).id,
        channel_type_id: create(:channel_type).id,
        title: "Test Channel #{Forgery(:name).company_name}",
        description: Forgery(:lorem_ipsum).paragraphs(3, random: true),
        tag_list: 'bla,title,description',
        images_attributes: {
          '0' => { image: fixture_file_upload(ImageSample.for_size('300x150')) }
        },
        cover_attributes: {
          image: fixture_file_upload(ImageSample.for_size('415x115'))
        },
        channel_location: 'Texas',
        approximate_start_date: (Time.zone.now + 5.days).to_date.inspect,
        channel_links_attributes: {
          '0' => { url: 'https://soundcloud.com/this-american-life/504-how-i-got-into-college' }
        }
      }
    end

    before do
      VCR.insert_cassette("#{described_class.to_s.underscore}_#{self.class.description.parameterize}")
    end

    context 'when given valid data' do
      before do
        post :create, params: { channel: valid_params }, format: :json
      end

      # leave it until next sprint, lets check stability
      it 'creates new channel' do
        channel = assigns(:channel)

        expect(response).not_to be_redirect
        expect(channel).not_to be_new_record
        expect(channel.tag_list.to_set).to eq %w[bla title description].to_set
        expect(channel.channel_links.count).to be 1
        expect(channel.images).not_to be_blank
        expect(response).not_to be_redirect
      end
      # it { expect(response).not_to be_redirect }

      it { expect(response).to be_successful }
      it { expect(assigns(:channel).channel_links.count).to be 1 }
      it { expect(assigns(:channel).images).not_to be_blank }
      it { expect(assigns(:channel).tag_list.to_set).to eq %w[bla title description].to_set }
    end

    it 'not allows to create new channel' do
      @ability = Object.new
      @ability.extend(CanCan::Ability)
      allow(controller).to receive(:current_ability).and_return(@ability)
      allow(@ability).to receive(:can).with(:create_channel, Organization).and_return(false)
      post :create, params: { channel: valid_params }, format: :json

      expect(response).to be_redirect
      expect(response).not_to be_successful
    end
  end

  describe 'POST :list' do
    context 'when given approved channel' do
      let(:current_user) { channel.organizer }

      let!(:channel) { create(:approved_channel) }

      it 'lists channel' do
        @request.env['HTTP_REFERER'] = 'http://localhost:3000/whatever'
        expect(channel).not_to be_listed

        post :list, params: { id: channel.id }

        expect(response).to be_redirect
        expect(channel.reload).to be_listed
      end
    end
  end

  describe 'PUT :update' do
    let(:current_user) { channel.organizer }

    let!(:channel) { create(:approved_channel_with_image) }
    let(:category) { channel.category }
    let(:channel_type) { channel.channel_type }

    before { VCR.insert_cassette("#{described_class.to_s.underscore}_#{self.class.description.parameterize}") }

    it 'updates channel' do
      opts = {
        list_automatically_after_approved_by_admin: 1,
        category_id: category.id,
        channel_type_id: channel_type.id,
        title: 'Test Channel FOO',
        description: Forgery(:lorem_ipsum).paragraphs(3, random: true),
        tag_list: channel.tag_list,
        channel_links_attributes: {
          '0' => { 'url' => 'https://soundcloud.com/this-american-life/504-how-i-got-into-college' },
          '1' => { 'url' => 'https://soundcloud.com/this-american-life/500-500' }
        }
      }
      put :update, params: { id: channel.slug, channel: opts }, format: :json

      channel = Channel.last

      expect(channel.title).to eq('Test Channel FOO')
      expect(channel.channel_links.count).to eq(2)

      expect(response).to be_successful
    end
  end
end
