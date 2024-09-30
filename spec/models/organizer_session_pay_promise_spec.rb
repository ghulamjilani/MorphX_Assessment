# frozen_string_literal: true

require 'spec_helper'

describe OrganizerAbstractSessionPayPromise do
  describe 'validations' do
    it 'allows unique session/co-presenter combinations only' do
      session = create(:immersive_session)
      co_presenter = create(:presenter)

      create(:organizer_session_pay_promise, abstract_session: session, co_presenter: co_presenter)
      expect do
        create(:organizer_session_pay_promise, abstract_session: session, co_presenter: co_presenter)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
