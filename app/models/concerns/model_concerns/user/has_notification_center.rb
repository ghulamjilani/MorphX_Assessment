# frozen_string_literal: true

module ModelConcerns::User::HasNotificationCenter
  def reminder_notifications
    mailbox.notifications.preload(:sender).where('mailboxer_notifications.created_at < ? ',
                                                 Time.zone.now).order('mailboxer_notifications.created_at DESC')
  end

  # when user opens his Notification center,
  # mark all unread notifications as read ones.
  def mark_reminder_notifications_as_read(notifications_ids)
    Mailboxer::Receipt.where(receiver: self,
                             notification_id: notifications_ids).where.not(is_read: true).update_all(is_read: true)
    Mailboxer::Notification.where(id: notifications_ids).update_all(updated_at: Time.now)

    Rails.cache.delete(new_notifications_count_cache_key)
  end

  def mark_reminder_notifications_as_unread(notifications_ids)
    Mailboxer::Receipt.where(receiver: self,
                             notification_id: notifications_ids).where.not(is_read: false).update_all(is_read: false)
    Mailboxer::Notification.where(id: notifications_ids).update_all(updated_at: Time.now)

    Rails.cache.delete(new_notifications_count_cache_key)
  end

  def new_notifications_count
    Rails.cache.fetch(new_notifications_count_cache_key) do
      reminder_notifications.unread.count
    end.to_i
  end

  def blocking_notifications_html
    ability ||= ::AbilityLib::Legacy::Ability.new(self).tap do |ability|
      ability.merge(::AbilityLib::Legacy::AccountingAbility.new(self))
      ability.merge(::AbilityLib::Legacy::NonAdminCrudAbility.new(self))
    end

    BlockingNotificationPresenter.new(self, ability).to_s
  end

  def blocking_notifications
    ability ||= ::AbilityLib::Legacy::Ability.new(self).tap do |ability|
      ability.merge(::AbilityLib::Legacy::AccountingAbility.new(self))
      ability.merge(::AbilityLib::Legacy::NonAdminCrudAbility.new(self))
    end

    BlockingNotificationPresenter.new(self, ability).notifications
  end
end
