# frozen_string_literal: true

require 'spec_helper'

describe NotificationsController do
  let(:current_user) { create(:user) }

  before do
    sign_in current_user, scope: :user
  end

  describe 'GET :index' do
    render_views
    let!(:notification) do
      create(:unread_notification,
             created_at: 12.hours.ago,
             expires: 10.minutes.from_now,
             notified_object: current_user)
    end

    describe '.html request format' do
      it 'does not fail' do
        get :index, format: :html

        expect(assigns(:notifications)).to eq([notification])

        expect(response).to be_successful
      end
    end

    describe '.json request format' do
      it 'does not fail' do
        get :index, format: :json

        expect(assigns(:notifications)).to eq([notification])

        expect(response).to be_successful
      end
    end
  end

  describe 'POST :bulk_read' do
    let!(:notification) do
      create(:unread_notification,
             created_at: 12.hours.ago,
             expires: 10.minutes.from_now,
             notified_object: current_user)
    end

    it 'works' do
      expect_any_instance_of(User).to receive(:mark_reminder_notifications_as_read)

      post :bulk_read, params: { ids: [notification.id] }

      expect(response).to be_successful
    end
  end

  describe 'DELETE :destroy_all' do
    let!(:notification) do
      create(:unread_notification,
             created_at: 12.hours.ago,
             expires: 10.minutes.from_now,
             notified_object: current_user)
    end

    it 'works' do
      expect(Mailboxer::Notification.count).to eq(1)

      delete :destroy_all, xhr: true

      expect(response).to be_successful
      expect(Mailboxer::Notification.count).to eq(0)
    end
  end

  describe 'DELETE :destroy' do
    let!(:notification) do
      create(:unread_notification,
             created_at: 12.hours.ago,
             expires: 10.minutes.from_now,
             notified_object: current_user)
    end

    it 'works' do
      expect(Mailboxer::Notification.count).not_to be_zero

      delete :destroy, params: { id: notification.id }

      expect(response).to be_redirect
      expect(Mailboxer::Notification.count).to be_zero
    end
  end

  describe 'POST :mark_as_read' do
    let!(:notification) do
      create(:unread_notification,
             created_at: 12.hours.ago,
             expires: 10.minutes.from_now,
             notified_object: current_user)
    end

    it 'mark_as_read' do
      expect_any_instance_of(User).to receive(:mark_reminder_notifications_as_read)

      post :mark_as_read, params: { id: notification.id }

      expect(response).to be_redirect
    end
  end
end
