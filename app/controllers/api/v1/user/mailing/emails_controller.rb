# frozen_string_literal: true

module Api
  module V1
    module User
      module Mailing
        class EmailsController < Api::V1::User::Mailing::ApplicationController
          def create
            q = params[:q]
            ids = params.require(:contact_ids)
            status = if params[:status].is_a?(Array)
                       params[:status].select do |p|
                         (0..6).cover?(p.to_i)
                       end
                     elsif params[:status] == 'all' || params[:status].nil? || params[:status].blank?
                       (0..6)
                     else
                       (0..6).cover?(params[:status].to_i) ? params[:status].to_i : (0..6)
                     end
            query = current_user.contacts.where(status: status)
            query = query.where('name ILIKE ? OR email LIKE ?', "%#{q}%", "%#{q.downcase}%") if q.present?
            @contacts = if ids == 'all'
                          query.all
                        else
                          query.where(id: ids)
                        end
            contact_ids = @contacts.pluck(:id)
            subject = params.require(:subject).first(80)
            body = params.require(:body).to_s.strip.html_safe
            @email = {
              body: body,
              subject: subject
            }
            @template = ::Mailing::Template::ALL.find do |t|
              t[:id] == params[:template_id]
            end || Mailing::Template::GENERAL
            EmailJobs::SendEmailJob.perform_async(current_user.id, contact_ids, body, subject, @template[:id], @template[:layout])

            render :preview
          end

          def preview
            ids = params.require(:contact_ids)
            @contacts = current_user.contacts.where(id: ids)
            contact = @contacts.first
            subject = params.require(:subject).first(80)
            body = params.require(:body).to_s.strip.html_safe
            @template = ::Mailing::Template::ALL.find do |t|
              t[:id] == params[:template_id]
            end || Mailing::Template::GENERAL
            replacements = { '[username]' => (contact&.name || 'John Doe') }
            preview_email = contact&.email || 'user@example.com'

            preview = Mailer.custom_email(email: preview_email, content: body, subject: subject,
                                          replacements: replacements, template: @template[:id], layout: @template[:layout]).body.to_s.html_safe

            @email = {
              body: body,
              subject: subject,
              preview: preview
            }
          end
        end
      end
    end
  end
end
