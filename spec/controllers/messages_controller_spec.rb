# frozen_string_literal: true

require 'spec_helper'

describe MessagesController do
  before do
    sign_in current_user, scope: :user
  end

  describe 'GET :new' do
    render_views

    context 'when presenters' do
      let(:user) { create(:user) }
      let(:current_user) { create(:user) }

      it 'does not fail' do
        get :new, params: { receiver: user.slug }, format: :js

        expect(response).to be_successful
      end
    end

    context 'when organizations' do
      let(:organization) { create(:organization) }
      let(:current_user) { create(:user) }

      it 'does not fail' do
        get :new, params: { receiver: organization.slug }, format: :js

        expect(response).to be_successful
      end
    end
  end

  describe 'GET :index' do
    render_views
    let(:current_user) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    before do
      receipt1 = current_user.send_message(user2, 'Body', 'Subject')
      user2.reply_to_all(receipt1, 'Reply body 1')

      user3.send_message(current_user, 'Hello world',
                         'This message is ought to be archived').conversation.move_to_trash(current_user)
    end

    describe '.html request format' do
      it 'does not fail' do
        get :index, format: :html

        expect(response).to be_successful
      end
    end

    describe '.json request format' do
      it 'does not fail' do
        get :index, format: :json

        expect(response).to be_successful
      end
    end
  end

  describe 'POST :create' do
    let(:current_user) { create(:user) }

    context 'when presenters' do
      let(:user2) { create(:user) }
      let(:valid_attributes) { { recipient: user2.slug, subject: 'subject1', body: 'body1' } }

      describe 'with valid params' do
        it 'creates a new Mailboxer::Message' do
          expect do
            post :create, params: { message: valid_attributes }, format: :js
          end.to change(Mailboxer::Message, :count).by(1)
        end

        it 'redirects to the created message' do
          post :create, params: { message: valid_attributes }, format: :js
          expect(response).to be_successful
        end
      end

      describe 'with invalid params' do
        it "re-renders the 'new' template" do
          post :create, params: { message: { recipient: user2.slug } }, format: :js
          expect(response).to render_template('messages/create')
        end
      end
    end
  end

  context 'when organizations' do
    let(:current_user) { create(:user) }
    let(:organization) { create(:organization) }
    let(:valid_attributes) { { recipient: organization.slug, subject: 'subject1', body: 'body1' } }

    describe 'with valid params' do
      it 'creates a new Mailboxer::Message' do
        expect do
          post :create, params: { message: valid_attributes }, format: :js
        end.to change(Mailboxer::Message, :count).by(1)
      end

      it 'redirects to the created message' do
        post :create, params: { message: valid_attributes }, format: :js
        expect(response).to be_successful
      end
    end

    describe 'with invalid params' do
      it "re-renders the 'new' template" do
        post :create, params: { message: { recipient: organization.slug } }, format: :js
        expect(response).to render_template('messages/create')
      end
    end
  end
end
