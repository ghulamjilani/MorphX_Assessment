# frozen_string_literal: true

require 'spec_helper'

describe ConversationsController do
  describe 'GET :preview_modal' do
    render_views
    let(:current_user) { create(:user) }

    it 'works' do
      sign_in current_user, scope: :user

      user2 = create(:user)

      expect(Mailboxer::Conversation.count).to eq(0)
      user2.send_message(current_user, 'body', 'subject')
      expect(Mailboxer::Conversation.count).to eq(1)

      conversation = Mailboxer::Conversation.last

      get :preview_modal, params: { id: conversation.id }, format: :js
    end
  end
end
