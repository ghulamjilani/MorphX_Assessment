# frozen_string_literal: true

class BecomePresenter::SaveUserInfo
  def initialize(user, user_params)
    @user_params = user_params
    @user = user
    @is_new = @user.new_record?
    @errors = []
  end

  def execute
    @user.during_bp_steps = true
    @user.build_user_account unless @user.user_account
    @user.build_presenter unless @user.presenter
    @user.attributes = @user_params
    @user.set_authentication_token if @user.new_record? && @user.authentication_token.blank?
    @user.set_display_name

    if @is_new
      @user.before_create_generic_callbacks_without_skipping_validation
    else
      time = CheckLastSeenBecomePresenterStep.delay_in_minutes.minutes.from_now
      CheckLastSeenBecomePresenterStep.perform_at(time, @user.id)

      if @user.email_was.blank?
        @user.skip_reconfirmation!
      end
    end

    if @user.save
      if [nil,
          Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::ABOUT].include?(@user.presenter.last_seen_become_presenter_step)
        @user.presenter.update({ last_seen_become_presenter_step: Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP1 })
      end

      if @is_new
        Mailer.user_signed_up(@user.id).deliver_later
        time = CheckLastSeenBecomePresenterStep.delay_in_minutes.minutes.from_now
        CheckLastSeenBecomePresenterStep.perform_at(time, @user.id)
      end
      true
    else
      Rails.logger.debug errors
      false
    end
  end

  attr_reader :user

  def is_new?
    @is_new
  end

  def errors
    @errors << @user.errors.full_messages if @user.errors.present?
    unless @user.user_account.valid?
      @errors << @user.user_account.errors.full_messages
    end
    @errors.flatten.uniq.compact.join('. ')
  end
end
