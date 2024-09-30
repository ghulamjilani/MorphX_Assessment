# frozen_string_literal: true
# require 'spec_helper'
# require 'sidekiq/testing'

# find all changes by TEMPORARYDISABLE
# describe CheckSessionWaitingList do
# describe "queuing" do
#   context "when session#max_number_of_immersive_participants is increased and waiting list is not blank" do
#     let(:session) { build(:immersive_session, min_number_of_immersive_and_livestream_participants: 2, max_number_of_immersive_participants: 2) }
#
#     it 'is queued' do
#       session.save!
#
#       user1 = create(:participant).user
#       user2 = create(:participant).user
#
#       user3 = create(:participant).user
#
#       create(:session_participation, session: session, participant: user1.participant)
#       create(:session_participation, session: session, participant: user2.participant)
#
#       #session.create_session_waiting_list!
#       session.session_waiting_list.users << user3
#
#       session.max_number_of_immersive_participants = session.max_number_of_immersive_participants + 1
#
#       session.save!
#       #
#       # expect(described_class).to have_queued(session.id)
#     end
#   end
# end
# describe ".perform(session_id)" do
#   let(:session) { create(:published_session) }
#
#   #find all changes by TEMPORARYDISABLE
#   xit 'notifies people' do
#     skip
#     user1 = create(:user)
#     session.session_waiting_list.users << user1
#
#     Sidekiq::Testing.inline! do
#       described_class.perform_async(session.id)
#     end
#   end
# end
# end
