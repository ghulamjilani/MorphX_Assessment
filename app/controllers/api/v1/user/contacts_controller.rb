# frozen_string_literal: true

class Api::V1::User::ContactsController < Api::V1::User::ApplicationController
  before_action :set_contact, only: [:update]
  before_action :offset_limit, only: %i[index destroy import_from_csv]
  before_action :load_contacts, only: %i[index destroy export_to_csv]

  def index
    @count = @query.count
    @contacts = @query.order('created_at DESC').limit(@limit).offset(@offset).preload(contact_user: :image)
  end

  def create
    email = params[:email]
    @user = ::User.find_or_initialize_by(email: email.to_s.downcase)
    public_display_name = @user.public_display_name || params[:public_display_name]
    begin
      @user.valid?
      if @user.errors[:email].blank?
        @contact = Contact.create!(for_user: current_user, contact_user_id: @user.id, email: email,
                                   name: public_display_name)
      else
        render_json(404, 'Email is invalid') and return
      end
    rescue ActiveRecord::RecordInvalid => e
      if e.message.include?('has already been taken')
        render_json(404,
                    I18n.t('controllers.contacts.create_error')) and return
      end
    end
    render :show
  end

  def update
    @contact.update!(contact_params)
    render :show
  end

  def destroy
    @query.destroy_all
    query = current_user.contacts.order('created_at DESC')
    @count = query.count
    @contacts = query.limit(@limit)
    render :index
  end

  def import_from_csv
    begin
      Contact.import(params[:file], current_user.id)
    rescue StandardError => e
      render_json(404, e.message) and return
    end
    query = current_user.contacts.order('created_at DESC')
    @count = query.count
    @contacts = query.limit(@limit)
    render :index
  end

  def export_to_csv
    @contacts = @query.order('created_at DESC')
    file = CSV.generate(headers: true) do |csv|
      csv << ['First Name', 'Last Name', 'Email', 'Status']
      @contacts.each do |contact|
        name = contact.name.to_s.split
        first_name = name.first
        name.slice!(0)
        last_name = name.join(' ')
        csv << [
          first_name,
          last_name,
          contact.email,
          contact.status
        ]
      end
    end

    filename = 'contacts.csv'

    send_data(file, filename: filename) and return
  end

  private

  def set_contact
    @contact = current_user.contacts.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(
      :name,
      :email
    )
  end

  def load_contacts
    q = params[:q]
    status = if params[:status].is_a?(Array)
               params[:status].select do |p|
                 (0..6).cover?(p.to_i)
               end
             elsif params[:status] == 'all' || params[:status].nil? || params[:status].blank?
               (0..6)
             else
               (0..6).cover?(params[:status].to_i) ? params[:status].to_i : (0..6)
             end
    @query = current_user.contacts.where(status: status)
    @query = @query.where('name ILIKE ? OR email LIKE ?', "%#{q}%", "%#{q.downcase}%") if q.present?
    @query = @query.where(id: params[:ids]) if params[:ids].present? && params[:ids] != 'all'
  end
end
