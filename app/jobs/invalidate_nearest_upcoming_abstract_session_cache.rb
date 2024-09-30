# frozen_string_literal: true

class InvalidateNearestUpcomingAbstractSessionCache < ApplicationJob
  def perform(abstract_session_type, abstract_session_id)
    abstract_session = abstract_session_type.constantize.find(abstract_session_id)

    abstract_session.organizer.invalidate_nearest_abstract_session_cache

    if abstract_session.is_a?(Session)
      abstract_session.session_participations.each do |gp|
        gp.user.invalidate_nearest_abstract_session_cache
      end

      abstract_session.livestreamers.each do |l|
        l.user.invalidate_nearest_abstract_session_cache
      end

      abstract_session.session_co_presenterships.each do |sc|
        sc.user.invalidate_nearest_abstract_session_cache
      end
    else
      raise "can not interpret #{abstract_session.class}"
    end
  end
end
