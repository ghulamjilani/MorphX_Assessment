# frozen_string_literal: true

class MailerPreview < ApplicationMailerPreview
  def lets_talk
    user = User.order(Arel.sql('RANDOM()')).first
    Mailer.lets_talk({
                       name: user.display_name,
                       company: 'Apple Inc.',
                       first_name: user.first_name,
                       last_name: user.last_name,
                       email: user.email,
                       phone: '+123456789000',
                       about: 'I like my work, I like to work on Saturdays. On Sundays, of course, too.',
                       plan: 'ULTRAXXXXL',
                       configured_autonomous_camera: 'YES',
                       multi_instructor_capability: 'NO',
                       single_classes_count: 3,
                       single_classes_cost: 99.99,
                       new_subscriptions_count: 100,
                       new_subscriptions_cost: 19.99
                     })
  end

  def share_via_email
    user_from = User.order(Arel.sql('RANDOM()')).first
    user_to = User.order(Arel.sql('RANDOM()')).first
    session = Session.order(Arel.sql('RANDOM()')).first
    message = "Hey, check this out! #{session.default_title} #{session.absolute_path}"
    subject = "#{user_from.display_name} shared a session with you on #{Rails.application.credentials.global[:service_name]}."
    Mailer.share_via_email(user_to.email, message, subject)
  end

  def share_user_via_email
    email = Forgery(:internet).email_address
    user = User.order(Arel.sql('RANDOM()')).first || FactoryBot.create(:user)
    Mailer.share_model_via_email(email, user)
  end

  def share_channel_via_email
    email = Forgery(:internet).email_address
    channel = Channel.order(Arel.sql('RANDOM()')).first || FactoryBot.create(:channel)
    Mailer.share_model_via_email(email, channel)
  end

  def share_session_via_email
    email = Forgery(:internet).email_address
    session = Session.order(Arel.sql('RANDOM()')).first || FactoryBot.create(:session)
    Mailer.share_model_via_email(email, session)
  end

  def share_recording_via_email
    email = Forgery(:internet).email_address
    recording = Recording.order(Arel.sql('RANDOM()')).first || FactoryBot.create(:recording)
    Mailer.share_model_via_email(email, recording)
  end

  def share_video_via_email
    email = Forgery(:internet).email_address
    video = Video.order(Arel.sql('RANDOM()')).first || FactoryBot.create(:video)
    Mailer.share_model_via_email(email, video)
  end

  def system_parameter_changed
    Mailer.system_parameter_changed(SystemParameter.first || SystemParameter.new(key: :project_collapse_enabled,
                                                                                 value: 1.0))
  end

  def twitter_widget_create_failed
    Mailer.twitter_widget_create_failed(Session.order(Arel.sql('RANDOM()')).first.id)
  end

  def vod_didnt_became_available_on_time
    model = Session.order('RANDOM()').limit(1).first
    Mailer.vod_didnt_became_available_on_time(model)
  end

  def invitation_instructions_for_referred_friend
    invited_user = User.where.not(invited_by_id: nil).sample

    if invited_user.present?
      Mailer.invitation_instructions invited_user, 'dummy-token'
    else
      invited_by = User.order(Arel.sql('RANDOM()')).first

      user = User.invite!({ email: "user#{rand(4000)}@example.com" }, invited_by,
                          &:before_create_generic_callbacks_and_skip_validation)
      Mailer.invitation_instructions user, 'dummy-token'
    end
  end

  def invitation_instructions_for_referred_friend_when_preview_refer_friend
    invited_user = User.where.not(invited_by_id: nil).sample

    if invited_user.present?
      Mailer.invitation_instructions invited_user, 'dummy-token', preview_only: true
    else
      invited_by = User.order(Arel.sql('RANDOM()')).first

      user = User.invite!({ email: "user#{rand(4000)}@example.com" }, invited_by,
                          &:before_create_generic_callbacks_and_skip_validation)
      Mailer.invitation_instructions user, 'dummy-token', preview_only: true
    end
  end

  def new_paypal_donation
    Mailer.new_paypal_donation(PaypalDonation.first.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def social_user_welcome
    Mailer.social_user_welcome(User.order(Arel.sql('RANDOM()')).first.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def confirmation_instructions
    user = User.order(Arel.sql('RANDOM()')).first
    Mailer.confirmation_instructions(user, 'dummy-token')
  rescue StandardError => e
    fallback_mail(e)
  end

  def reset_password_instructions
    Mailer.reset_password_instructions User.new(email: 'test@email.com'), 'dummy-token'
  end

  def user_signed_up
    Mailer.user_signed_up(User.order(Arel.sql('random()')).pick(:id))
  end

  def welcome_stopped_during_becoming_a_presenter
    Mailer.welcome_stopped_during_becoming_a_presenter(User.order(Arel.sql('random()')).pick(:id))
  end

  def becoming_a_presenter_reached_step
    user = User.order(Arel.sql('RANDOM()')).first

    step = [
      Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP1,
      Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP2,
      Presenter::LAST_SEEN_BECOME_PRESENTER_STEPS::STEP3
    ].sample

    Mailer.becoming_a_presenter_reached_step(user.id, step)
  rescue StandardError => e
    fallback_mail(e)
  end

  def vod_became_available_for_organizer
    Mailer.vod_became_available_for_organizer(Session.order(Arel.sql('random()')).pick(:id))
  end

  def vod_just_became_available_for_purchase
    Mailer.vod_just_became_available_for_purchase(User.order(Arel.sql('random()')).pick(:id), Session.order(Arel.sql('RANDOM()')).first)
  end

  def money_refund_receipt
    log_transaction_id = LogTransaction.joins("LEFT JOIN payment_transactions ON log_transactions.payment_transaction_id=payment_transactions.id and log_transactions.payment_transaction_type='PaymentTransaction'")
                                       .where.not(payment_transactions: { id: nil })
                                       .order(Arel.sql('random()'))
                                       .pick(:id)
    Mailer.money_refund_receipt(User.order(Arel.sql('random()')).pick(:id), log_transaction_id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def pending_refund_caused_by_reason_other_than_updated_start_at
    pending_refund = PendingRefund.order(Arel.sql('RANDOM()')).first

    Mailer.pending_refund_caused_by_reason_other_than_updated_start_at pending_refund.id
  rescue StandardError => e
    fallback_mail(e)
  end

  def pending_refund_caused_by_updated_start_at__for_session_braintree_participant
    pending_refund = PendingRefund.order(Arel.sql('RANDOM()')).first

    Mailer.pending_refund_caused_by_updated_start_at pending_refund.id, SessionParticipation.order(Arel.sql('RANDOM()')).first
  rescue StandardError => e
    fallback_mail(e)
  end

  def pending_refund_caused_by_updated_start_at__for_session_co_presenters
    Mailer.pending_refund_caused_by_updated_start_at PendingRefund.order(Arel.sql('random()')).pick(:id), SessionCoPresentership.order(Arel.sql('RANDOM()')).first
  rescue StandardError => e
    fallback_mail(e)
  end

  def pending_refund_caused_by_updated_start_at__for_session_livestreamer
    Mailer.pending_refund_caused_by_updated_start_at PendingRefund.order(Arel.sql('random()')).pick(:id), Livestreamer.order(Arel.sql('RANDOM()')).first
  rescue StandardError => e
    fallback_mail(e)
  end

  def ban_user
    room_member = RoomMember.banned.order(Arel.sql('RANDOM()')).first || ::FactoryBot.create(:room_member,
                                                                                             banned: true, ban_reason: BanReason.order(Arel.sql('RANDOM()')).first)

    Mailer.ban_user(room_member.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def unban_user
    room_member = RoomMember.not_banned.order(Arel.sql('RANDOM()')).first || ::FactoryBot.create(:room_member)

    Mailer.unban_user(room_member.id)
  end

  def locked_presenter_balance
    Mailer.locked_presenter_balance(Presenter.order(Arel.sql('random()')).pick(:id), 'admin1@example.com')
  end

  def time_to_service
    Mailer.time_to_service(from_user_id: User.order(Arel.sql('RANDOM()')).first.id, email: 'admin1@example.com',
                           user_name: User.order(Arel.sql('RANDOM()')).first.full_name, content: 'We have been waiting for this moment!')
  end

  def new_site_email_for_existing_users
    Mailer.custom_email(email: 'admin1@example.com', content: '',
                        subject: "#{Rails.application.credentials.global[:host]} has a new home - welcome to #{Rails.application.credentials.global[:service_name]}!", template: 'new_site_email_for_existing_users', layout: 'email')
  end

  def custom_email_layout_email
    user = User.order(Arel.sql('RANDOM()')).first
    replacements = { '[username]' => user.display_name }
    Mailer.custom_email(email: 'admin1@example.com', replacements: replacements,
                        content: "Hello [username]! https://#{Rails.application.credentials.global[:host]} is amazing! Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.", subject: 'What is Lorem Ipsum?', template: 'email_general', layout: 'email')
  end

  def custom_email_layout_email2
    user = User.order(Arel.sql('RANDOM()')).first
    replacements = { '[username]' => user.display_name }
    Mailer.custom_email(email: 'admin1@example.com', replacements: replacements,
                        content: "Hello [username]! https://#{Rails.application.credentials.global[:host]} is amazing!  Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.", subject: 'What is Lorem Ipsum?', template: 'email2_general', layout: 'email2')
  end

  def custom_email_layout_email3
    user = User.order(Arel.sql('RANDOM()')).first
    replacements = { '[username]' => user.display_name }
    Mailer.custom_email(email: 'admin1@example.com', replacements: replacements,
                        content: "Hello [username]! https://#{Rails.application.credentials.global[:host]} is amazing! Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.", subject: 'What is Lorem Ipsum?', template: 'email3_general', layout: 'email3', title_text: 'Dummy Title')
  end

  def bulk_custom_email
    Mailer.bulk_custom_email(emails: ['admin1@example.com', 'user1@example.com'],
                             content: "Hello! https://#{Rails.application.credentials.global[:host]} is amazing!  Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.", subject: 'What is Lorem Ipsum?')
  end
end
