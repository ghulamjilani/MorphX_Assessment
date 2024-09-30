# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include ControllerConcerns::SharedControllerHelper
  include ControllerConcerns::GoService
  include ControllerConcerns::EverflowTracking
  include ControllerConcerns::CallToActionRedirectsHelper
  include ControllerConcerns::DropboxUtils
  include ControllerConcerns::LatestNotifications
  include ControllerConcerns::JsonGlobal
  include ControllerConcerns::RedirectUtils
  include ControllerConcerns::Api::V1::CookieAuth

  def respond_to_blocking_notification_close_request(obj)
    if obj.present?
      obj.touch(:blocking_notification_is_forcefully_closed_at)

      case obj
      when SessionInvitedImmersiveParticipantship
        obj2 = obj.session.session_invited_livestream_participantships.where(participant: obj.participant).pending.where(blocking_notification_is_forcefully_closed_at: nil).first
        obj2&.touch(:blocking_notification_is_forcefully_closed_at)
      when SessionInvitedLivestreamParticipantship
        obj2 = obj.session.session_invited_immersive_participantships.where(participant: obj.participant).pending.where(blocking_notification_is_forcefully_closed_at: nil).first
        obj2&.touch(:blocking_notification_is_forcefully_closed_at)
        # TODO: Do we need blocking_notification for channel co-presenters?
        # elsif obj.is_a?(ChannelInvitedParticipantshipsController)
        #   obj2 = obj.channel.channel_invited_presenterships.where(presenter: obj.presenter).pending.where(blocking_notification_is_forcefully_closed_at: nil).first
        #   if obj2.present?
        #     obj2.touch(:blocking_notification_is_forcefully_closed_at)
        #   end
      end
    end
    respond_to do |format|
      format.js { render plain: "$('.FlashBox:visible').remove();$('.FlashBox:first').show()", layout: true }
    end
  end

  layout :layout

  def ensure_timecop_travel_is_not_used
    if session[:timecop_adjusted_time].present? # see https://github.com/ferndopolis/timecop-console/blob/master/lib/timecop_console.rb
      flash[:notice] = 'Please reset virtual time before proceeding'
      redirect_back fallback_location: dashboard_path
    end
  end

  def generate_client_token
    @client_token = if current_user.braintree_customer_id.present?
                      Braintree::ClientToken.generate(customer_id: current_user.braintree_customer_id)
                    else
                      Braintree::ClientToken.generate
                    end
  end

  # @param model - instance of Session class
  # @param description - string for calendar event description
  def render_ical(model, description)
    require 'icalendar/tzinfo'

    calendar = Icalendar::Calendar.new

    event_start = model.start_at.utc
    event_end   = model.end_at.utc

    tzid     = 'UTC'
    tz       = TZInfo::Timezone.get tzid
    timezone = tz.ical_timezone event_start
    calendar.add_timezone timezone

    calendar.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new event_start, tzid: tzid
      e.dtend       = Icalendar::Values::DateTime.new event_end,   tzid: tzid
      e.summary     = model.always_present_title

      if description.present?
        e.description = description
      end
    end

    calendar.publish

    respond_to do |wants|
      wants.ics do
        render plain: calendar.to_ical
      end
    end
  end

  # this method has to skip errors that are highlighted in form
  # and display errors that are caused by validation errors in invited participants and presenters
  def display_interactor_errors(model)
    # nested_model_errors could be like:
    # {
    #  :"session_invited_immersive_co_presenterships.base" => ["co-presenter is already invited as participant to the session"],
    #  :"session_invited_immersive_participantships.base" => ["participant is already invited as co-presenter to the session"]
    # }
    # model.valid? rescue nil #NOTE: that #valid? flushes all manually set #errors(outside model)

    flash_errors = []

    nested_model_errors = model.errors.to_hash.select do |key, _value|
      lambda do
        return true if key.to_s.include?('participant')
        return true if key.to_s.include?('session_')
        return true if key.eql?(:base)

        key.to_s.start_with?('room.')
      end.call
    end

    if nested_model_errors.present?
      flash_errors << nested_model_errors.values.flatten
    end

    if flash_errors.present?
      flash.now[:error] = flash_errors.flatten.join(', ').html_safe
    end
  end

  def profile_attributes
    if params[:profile].present?
      params.require(:profile).permit(
        :birthdate,
        :country,
        :email,
        :first_name,
        :last_name,
        :display_name,
        :gender,
        :time_format,
        :talent_list,
        :manually_set_timezone
      ).tap do |attributes|
        attributes['birthdate'] =
          Date.new(attributes['birthdate(1i)'].to_i, attributes['birthdate(2i)'].to_i, attributes['birthdate(3i)'].to_i)
      rescue ArgumentError => e
        Rails.logger.debug "attributes: #{attributes.inspect}"
        Rails.logger.debug e.message
      end
    end
  end

  def channel_params
    params.require(:channel).permit(
      :approximate_start_date,
      :category_id,
      :channel_location,
      :channel_type_id,
      :description,
      :display_empty_blog,
      :im_conversation_enabled,
      :is_default,
      :list_automatically_after_approved_by_admin,
      :live_guide_is_visible,
      :show_comments,
      :show_reviews,
      :show_documents,
      :tag_list,
      :tagline,
      :title,
      :list_ids,
      cover_attributes: %i[id place_number description _destroy crop_x crop_y crop_w crop_h rotate is_main image],
      logo_attributes: %i[id crop_x crop_y crop_w crop_h rotate original],
      images_attributes: %i[id place_number description _destroy crop_x crop_y crop_w crop_h rotate is_main image],
      channel_links_attributes: %i[id place_number url description _destroy]
    ).tap do |hash|
      hash[:list_automatically_after_approved_by_admin] =
        params[:channel][:list_automatically_after_approved_by_admin].present?
    end
  end

  private

  def layout
    if request.url.include?('/kss')
      return 'kss/application'
    end

    if devise_controller? && devise_mapping.name == :admin
      'admin'
    else
      'application'
    end
  end

  def set_channel_form_gon_params
    gon.channel_materials  = @channel.materials
    gon.channel_attributes = @channel.attributes
    gon.max_images_size         = SystemParameter.channel_images_max_count.to_i
    gon.max_links_size          = SystemParameter.channel_links_max_count.to_i

    not_new_but_still_can_change = @channel.status == Channel::Statuses::DRAFT || @channel.status == Channel::Statuses::PENDING_REVIEW
    gon.can_change_list_automatically_after_approved_by_admin = !@channel.persisted? || not_new_but_still_can_change
    gon.channel_submit_buttons = channel_submit_buttons
  end

  # (1)
  # Submit for Approval
  # Save as Draft
  #
  # (2)
  # Submit for Approval
  # Update Draft
  #
  # (3)
  # just submitted for review, under review
  # OR after it was listed
  # Update Channel
  #
  # (4)
  # approved but not listed yet
  # List Channel
  # Update Channel
  #
  # @return [Array]
  def channel_submit_buttons
    if !@channel.persisted? # (1)
      ['Submit for Approval', 'Save as Draft'].reverse
    elsif @channel.status == Channel::Statuses::DRAFT # (2)
      ['Submit for Approval', 'Update Draft'].reverse
    elsif @channel.status == Channel::Statuses::APPROVED # (4)
      ['List Channel', 'Update Channel'].reverse
    else
      ['Update Channel']
    end
  end
end
