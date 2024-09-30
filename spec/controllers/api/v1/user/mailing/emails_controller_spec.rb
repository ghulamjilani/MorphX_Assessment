# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::User::Mailing::EmailsController do
  describe '.json request format' do
    let(:auth_header_value) { "Bearer #{JwtAuth.user(current_user)}" }

    render_views

    before do
      request.headers['Authorization'] = auth_header_value
    end

    describe 'POST create:' do
      let(:contact) { create(:contact) }
      let(:current_user) { contact.for_user }
      let(:params) do
        {
          template_id: ::Mailing::Template::BASIC.sample[:id],
          contact_ids: [contact.id],
          body: Forgery(:lorem_ipsum).paragraphs(2, random: true),
          subject: Forgery(:lorem_ipsum).words(5, random: true)
        }
      end

      it 'returns successfull response' do
        post :create, params: params, format: :json
        expect(response).to be_successful
      end

      it 'enqueues mailing job' do
        expect do
          post :create, params: params, format: :json
        end.to change(EmailJobs::SendEmailJob.jobs, :size).by(1)
      end
    end

    describe 'GET show:' do
      let(:contact) { create(:contact) }
      let(:current_user) { contact.for_user }
      let(:params) do
        {
          id: 'preview',
          template_id: ::Mailing::Template::GENERAL[:id],
          contact_ids: [contact.id],
          body: Forgery(:lorem_ipsum).words(20, random: true),
          subject: Forgery(:lorem_ipsum).words(5, random: true)
        }
      end

      before do
        post :preview, params: params, format: :json
      end

      it { expect(response).to be_successful }

      it { expect(JSON.parse(response.body)['email']['preview']).to include(params[:body]) }

      context 'when user has no contacts' do
        let(:current_user) { create(:user) }

        it { expect(response).to be_successful }
      end
    end
  end
end
