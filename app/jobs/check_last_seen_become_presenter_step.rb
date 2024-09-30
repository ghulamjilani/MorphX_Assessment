# frozen_string_literal: true

class CheckLastSeenBecomePresenterStep < ApplicationJob
  # NOTE: this job is scheduled right after user visits *become a presenter* workflow
  #      but with some delay(to give enough time to complete all steps).
  def perform(user_id)
    user = User.find(user_id)
    presenter = user.try(:presenter)

    completed_whole_process = presenter.present? && presenter.channels.present?
    if completed_whole_process
      Rails.logger.info 'all good, user became a presenter'
    else
      notify_admins(user) unless user.fake
      notify_user(user)
    end
  end

  def self.delay_in_minutes
    60
  end

  private

  def notify_admins(user)
    presenter = user.try(:presenter)

    step_name = if presenter.blank? || (presenter.present? && presenter.last_seen_become_presenter_step.blank?)
                  Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP1
                else
                  presenter.last_seen_become_presenter_step
                end

    ::Mailer.becoming_a_presenter_reached_step(user.id, step_name).deliver_later
  end

  def notify_user(user)
    step = user.presenter.try(:last_seen_become_presenter_step)
    if [Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP2,
        Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP3].include?(step)
      ::Mailer.welcome_stopped_during_becoming_a_presenter(user.id).deliver_later
    end
  end
end
