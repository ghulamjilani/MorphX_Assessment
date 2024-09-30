# frozen_string_literal: true

class PublishFreeSessionThatJustGotApproved < ApplicationJob
  def perform(session_id)
    session = Session.find(session_id)

    if session.status == Session::Statuses::REQUESTED_FREE_SESSION_APPROVED
      if session.publish_after_requested_free_session_is_satisfied_by_admin
        session.update_attribute(:status, ::Session::Statuses::PUBLISHED)
        session.update_attribute(:publish_after_requested_free_session_is_satisfied_by_admin, nil)
      else
        Rails.logger.info "this session - #{session_id} should be automatically published in the first place"
      end

      LiveGuideChannelsAggregator.trigger_live_refresh
    else
      Rails.logger.info "this session - #{session_id} should be have proper status - instead #{session.status}"
    end
  end
end
