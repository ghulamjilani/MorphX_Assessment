# frozen_string_literal: true
class Contact < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::ActiveModel::Extensions

  scope :search_by_name_or_email, lambda { |query|
                                    where('contacts.name ILIKE :query OR contacts.email ILIKE :query', query: query)
                                  }
  belongs_to :for_user, class_name: 'User'
  belongs_to :contact_user, class_name: 'User', foreign_key: 'contact_user_id'

  validates :for_user, presence: true
  validates :contact_user_id, uniqueness: { scope: :for_user_id }, if: ->(obj) { obj.contact_user_id.present? }
  validates :email, uniqueness: { scope: :for_user_id }
  before_validation :set_default_email_name, on: :create
  after_create :new_contact_cable_notification
  # Subscription-(подписчики)
  # Trial-(на потом, статус для триал подписки)
  # One time(для юзеров купивших видео, реплей или аплоуд)
  # Canceled(отменившие подписку)
  # None(просто контакты)
  # Unpaid(не оплатившие подписку)
  enum status: {
    contact: 0,
    subscription: 1,
    unpaid: 2,
    canceled: 3,
    trial: 4,
    one_time: 5,
    opt_in: 6
  }
  def self.import(file, user_id)
    delimiter = ::CsvDelimiter.find(file.path)
    csv_file = CSV.parse(File.read(file.path), headers: true, col_sep: delimiter)
    headers = csv_file.headers
    email_key = headers.detect { |key_name| /email/i.match(key_name) }
    first_name_key = headers.detect { |key_name| /first name|full name/i.match(key_name) }
    last_name_key = headers.detect { |key_name| /last name|surname/i.match(key_name) }

    csv_file.each do |row|
      attrs = row.to_h
      next unless email_key

      email = attrs[email_key]
      next unless email

      name = [attrs[first_name_key], attrs[last_name_key]].compact.join(' ')
      contact_user = User.find_by(email: email)
      Contact.create(contact_user: contact_user, for_user_id: user_id, email: email, name: name)
    end
  end

  def seen!(logger_user_tag)
    self.originally_facebook_friend_and_not_seen_yet = false
    save!

    Rails.logger.info logger_user_tag + "#{inspect} has just been displayed in UI"
  end

  def avatar_url
    contact_user&.avatar_url || User.new.avatar_url
  end

  private

  def new_contact_cable_notification
    UsersChannel.broadcast_to(for_user,
                              event: 'new_contact',
                              data: {
                                id: id,
                                name: name,
                                email: email,
                                status: status,
                                contact_user_id: contact_user_id,
                                contact_user: {
                                  id: contact_user&.id,
                                  public_display_name: contact_user&.public_display_name,
                                  relative_path: contact_user&.relative_path,
                                  avatar_url: contact_user&.avatar_url
                                }
                              })
  end

  def set_default_email_name
    return unless contact_user

    self.email ||= contact_user.email
    self.name ||= contact_user.public_display_name
  end
end
