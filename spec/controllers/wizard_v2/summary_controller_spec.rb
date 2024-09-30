# frozen_string_literal: true

require 'spec_helper'

describe WizardV2::SummaryController do
  render_views

  before do
    sign_in current_user, scope: :user
  end

  describe 'GET :show' do
    context 'when non creator' do
      let(:current_user) { create(:approved_channel).organizer }

      it 'works' do
        get :show
        expect(response).to be_successful
      end
    end
  end
end
