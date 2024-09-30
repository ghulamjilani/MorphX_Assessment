# frozen_string_literal: true

FactoryBot.define do
  factory :organizer_abstract_session_pay_promise do
    association :abstract_session, factory: :immersive_session
    association :co_presenter, factory: :presenter
  end

  factory :organizer_session_pay_promise, class: 'OrganizerAbstractSessionPayPromise' do
    association :abstract_session, factory: :immersive_session
    association :co_presenter, factory: :presenter
  end

  factory :organizer_session_pay_promise_for_attended_user, parent: :organizer_session_pay_promise do
    after(:create) do |organizer_session_pay_promise|
      session = organizer_session_pay_promise.abstract_session

      room = session.room or raise 'can not get room'
      FactoryBot.create(:room_member,
                        kind: RoomMember::Kinds::CO_PRESENTER,
                        room: room,
                        abstract_user: organizer_session_pay_promise.co_presenter.user)
    end
  end
end
