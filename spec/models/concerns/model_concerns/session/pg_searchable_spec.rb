# frozen_string_literal: true

require 'spec_helper'

describe ModelConcerns::Session::PgSearchable do
  let(:session) { create(:published_livestream_session) }

  describe '#update_pg_search_document_now?' do
    subject { session.update_pg_search_document_now? }

    # context 'when called on a new record' do
    #   it { is_expected.to be_truthy }
    # end

    context 'when called on an old record' do
      before do
        session.update(description: 'new description')
      end

      it { is_expected.to be_falsey }
    end

    # context 'when updated an important attribute' do
    #   before do
    #     session.update(stopped_at: Time.now)
    #   end

    #   it { is_expected.to be_truthy }
    # end
  end
end
