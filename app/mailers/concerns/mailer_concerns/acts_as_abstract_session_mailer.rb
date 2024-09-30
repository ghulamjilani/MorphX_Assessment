# frozen_string_literal: true

module MailerConcerns::ActsAsAbstractSessionMailer
  extend ActiveSupport::Concern

  included do
    def model_name
      self.class.to_s.gsub('Mailer', '').downcase
    end
    private :model_name

    def model_class
      self.class.to_s.gsub('Mailer', '').constantize
    end
    private :model_class

    # TODO: - what if that was "sys credit" purchase?
    define_method 'you_obtained_live_access' do |session_id, user_id, payment_transaction_id, system_credit_entry_id|
      @user = User.find(user_id)
      model = model_class.find(session_id)
      instance_variable_set("@#{model_name}", model)

      @system_credit_entry = system_credit_entry_id ? SystemCreditEntry.find(system_credit_entry_id) : nil
      @payment_transaction = payment_transaction_id ? PaymentTransaction.find(payment_transaction_id) : nil

      if model.is_a?(Session)
        @livestreamer = model.livestreamers.where(participant: @user.participant).present?
      else
        raise "can not interpret #{model.inspect}"
      end

      @subject = if @payment_transaction.present? || @system_credit_entry.present?
                   "Your #{model_name} is confirmed and receipt attached"
                 else
                   "Your free #{model_name} is confirmed"
                 end

      @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                           subject: @subject,
                                                                           sender: nil,
                                                                           body: render_to_string(__method__,
                                                                                                  layout: false))
      mail to: @user.email,
           subject: @subject,
           template_path: 'mailboxer/notification_mailer',
           template_name: 'new_notification_email'
    end

    define_method "#{to_s.gsub('Mailer', '').downcase}_cancelled" do |session_id, recipient_user_id|
      @user = User.find(recipient_user_id)

      model = model_class.find(session_id)
      instance_variable_set("@#{model_name}", model)

      if model.is_a?(Session)
        @direct_from_name = model.channel.title
        @url = model.absolute_path
        title = model.always_present_title
      else
        raise ArgumentError
      end

      @subject = "#{model_name.capitalize} #{title} has been cancelled"
      @notification = ::Immerss::Mailboxer::Notification.save_with_receipt(user: @user,
                                                                           subject: @subject,
                                                                           sender: model.organizer,
                                                                           body: render_to_string(__method__,
                                                                                                  layout: false))

      mail to: @user.email,
           subject: @subject,
           template_path: 'mailboxer/notification_mailer',
           template_name: 'new_notification_email'
    end
  end
end
