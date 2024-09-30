# frozen_string_literal: true

class ContactsController < ApplicationController
  before_action :authenticate_user!

  def toggle_contact
    if (contact = Contact.where(for_user: current_user, contact_user_id: params[:contact_id]).first)
      contact.destroy!
      head :no_content
    else
      user = User.find(params[:contact_id])
      Contact.create!(for_user: current_user, contact_user_id: user.id, email: user.email,
                      name: user.public_display_name)
      head :created
    end
  end
end
