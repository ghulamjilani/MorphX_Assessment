# frozen_string_literal: true

class RecordingMailerPreview < ApplicationMailerPreview
  def ready
    recording = Recording.order(Arel.sql('RANDOM()')).first
    raise 'No Recording found, unable to show a preview' unless recording

    RecordingMailer.ready(recording.id)
  rescue StandardError => e
    fallback_mail(e)
  end

  def you_obtained_access
    recording = Recording.order(Arel.sql('RANDOM()')).first
    raise 'No Recording found, unable to run a preview' unless recording

    transaction = PaymentTransaction.order(Arel.sql('RANDOM()')).first
    raise 'No PaymentTransaction found, unable to show a preview' unless transaction

    user_id = User.order(Arel.sql('RANDOM()')).first.id
    RecordingMailer.you_obtained_access(recording.id, user_id, transaction.id)
  rescue StandardError => e
    fallback_mail(e)
  end
end
