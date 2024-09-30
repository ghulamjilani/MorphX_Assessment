# frozen_string_literal: true
class MarketingTools::OptInModalSubmit < MarketingTools::ApplicationRecord
  belongs_to :opt_in_modal, class_name: 'MarketingTools::OptInModal', inverse_of: :opt_in_modal_submits, foreign_key: :mrk_tools_opt_in_modal_id, primary_key: :id, counter_cache: :submits_count
  belongs_to :user, inverse_of: :opt_in_modal_submits, foreign_key: :user_uuid, primary_key: :uuid

  # For now data contains only email. This can be changed in the future so validation should be changed or removed
  validates :data, format: { with: URI::MailTo::EMAIL_REGEXP }

  after_commit :create_contact, on: :create

  private

  # For now data contains only email. This can be changed in the future so method should be changed too
  def create_contact
    email = data.to_s.downcase
    user = ::User.find_or_initialize_by(email: email)
    public_display_name = user.public_display_name || email
    begin
      user.valid?
      if user.errors[:email].blank?
        owner = opt_in_modal.channel.organizer
        Contact.create!(for_user: owner, contact_user_id: user.id, email: email, name: public_display_name, status: 6)
      end
    rescue StandardError
      # We don't need to catch the error, just do nothing if email invalid or contact already exists
      true
    end
  end
end
