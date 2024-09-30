# frozen_string_literal: true

ActiveAdmin.register Room do
  menu parent: 'Sessions'

  filter :id
  filter :actual_start_at
  filter :actual_end_at
  filter :status
  filter :abstract_session_type
  filter :abstract_session_id
  filter :recording
  filter :mic_disabled
  filter :video_disabled
  filter :presenter_user_id
  filter :recorder_type
  filter :vod_is_fully_ready
  filter :backstage
  filter :service_type
  filter :created_at
  filter :updated_at

  scope(:upcoming) { |scope| scope.where('now() < actual_end_at') }
  scope(:active) do |scope|
    scope.where(':time_now BETWEEN actual_start_at::timestamp AND actual_end_at::timestamp',
                { time_now: Time.zone.now })
  end

  action_item :control, only: :show do |object|
    link_to('Control', [:room_control, :service_admin_panel, :room, object])
  end

  index do
    selectable_column
    column :id
    column :actual_start_at
    column :actual_end_at
    column :status
    column :abstract_session, sortable: :abstract_session_id
    column :recording
    column :presenter_user, sortable: :presenter_user_id
    column :recorder_type
    column :service_type
    # column :livestream_up
    column :control do |object|
      link_to('Control', [:room_control, :service_admin_panel, object])
    end

    actions
  end

  actions :all, except: %i[new create destroy]

  form do |f|
    f.inputs do
      f.input :vod_is_fully_ready
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit!
    end

    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end

  member_action :stop_session, method: :get do
    if resource.closed?
      flash[:error] = 'Room is closed already'
    else
      ::Control::Room.new(resource).stop
      resource.abstract_session.update_column(:stop_reason, 'stopped_by_admin')
      flash[:notice] = 'Session successfully stopped'
    end
    redirect_back fallback_location: service_admin_panel_rooms_path
  end

  member_action :start_session, method: :get do
    if resource.awaiting?
      ::Control::Room.new(resource).start
      flash[:notice] = 'Session successfully started'
    else
      flash[:error] = 'Room status is different from awaiting'
    end
    redirect_back fallback_location: service_admin_panel_rooms_path
  end

  member_action :change_duration, method: :get do
    as = resource.abstract_session
    as.duration = if params[:increase].present?
                    as.duration + 15
                  else
                    as.duration - 15
                  end
    if as.save
      flash[:notice] = 'Duration successfully updated'
    else
      flash[:error] = as.errors.full_messages.join('.')
    end
    redirect_back fallback_location: service_admin_panel_rooms_path
  end

  member_action :room_control, method: :get do
    @room_members = resource.room_members.all
  end

  member_action :mute_room_toggle, method: :get do
    control = ::Control::Room.new(resource)
    if resource.mic_disabled
      control.unmute_all
    else
      control.mute_all
    end
    response ? (flash[:notice] = 'Updated') : (flash[:error] = 'Something went wrong')
    redirect_back fallback_location: service_admin_panel_rooms_path
  end

  member_action :cam_room_toggle, method: :get do
    control = ::Control::Room.new(resource)
    if resource.video_disabled
      control.start_all_videos
    else
      control.stop_all_videos
    end

    flash[:notice] = 'Updated'
    redirect_back fallback_location: service_admin_panel_rooms_path
  end

  member_action :backstage_room_toggle, method: :get do
    control = ::Control::Room.new(resource)
    if resource.backstage
      control.disable_all_backstage
    else
      control.enable_all_backstage
    end
    flash[:notice] = 'Updated'
    redirect_back fallback_location: service_admin_panel_rooms_path
  end

  member_action :unpin_room, method: :get do
    control = ::Control::Room.new(resource)
    control.unpin_all
    flash[:notice] = 'Updated'
    redirect_back fallback_location: service_admin_panel_rooms_path
  end

  member_action :toggle_share, method: :get do
    control = ::Control::Room.new(resource)
    control.toggle_share
    flash[:notice] = 'Updated'
    redirect_back fallback_location: service_admin_panel_rooms_path
  end

  member_action :mute_member_toggle, method: :get do
    control = ::Control::Room.new(resource)
    member = resource.room_members.find(params[:member_id])
    if member.mic_disabled
      control.unmute(member.id)
    else
      control.mute(member.id)
    end

    flash[:notice] = 'Updated'
    redirect_back fallback_location: service_admin_panel_rooms_path
  end

  member_action :cam_member_toggle, method: :get do
    control = ::Control::Room.new(resource)
    member = resource.room_members.find(params[:member_id])
    if member.video_disabled
      control.start_video(member.id)
    else
      control.stop_video(member.id)
    end

    flash[:notice] = 'Updated'
    redirect_back fallback_location: service_admin_panel_rooms_path
  end

  member_action :backstage_member_toggle, method: :get do
    control = ::Control::Room.new(resource)
    member = resource.room_members.find(params[:member_id])
    if member.backstage
      control.disable_backstage(member.id)
    else
      control.enable_backstage(member.id)
    end

    flash[:notice] = 'Updated'
    redirect_back fallback_location: service_admin_panel_rooms_path
  end

  member_action :pin_member_toggle, method: :get do
    control = ::Control::Room.new(resource)
    member = resource.room_members.find(params[:member_id])
    if member.pinned
      control.unpin(member.id)
    else
      control.pin(member.id)
    end

    flash[:notice] = 'Updated'
    redirect_back fallback_location: service_admin_panel_rooms_path
  end

  member_action :ban_member_toggle, method: :get do
    control = ::Control::Room.new(resource)
    member = resource.room_members.find(params[:member_id])
    if member.banned
      control.unban(member.id)
    else
      ban_reason_id = BanReason.first_or_create(name: 'Inappropriate behavior').id
      control.ban_kick(member.id, ban_reason_id)
    end

    flash[:notice] = 'Updated'
    redirect_back fallback_location: service_admin_panel_rooms_path
  end

  member_action :create_shared_interactive_access_token, method: :get do
    if resource.session.interactive_access_tokens.create(individual: false).present?
      flash[:notice] = 'Created'
    else
      flash[:error] = 'Failed. Probably you have one already?'
    end
    redirect_back fallback_location: service_admin_panel_rooms_path
  end

  member_action :create_shared_guest_interactive_access_token, method: :get do
    if resource.session.interactive_access_tokens.create(individual: false, guests: true).present?
      flash[:notice] = 'Created'
    else
      flash[:error] = 'Failed. Probably you have one already?'
    end
    redirect_back fallback_location: service_admin_panel_rooms_path
  end

  member_action :create_individual_interactive_access_token, method: :get do
    resource.session.interactive_access_tokens.create(individual: true)
    flash[:notice] = 'Created'
    redirect_back fallback_location: service_admin_panel_rooms_path
  end

  member_action :create_individual_guest_interactive_access_token, method: :get do
    resource.session.interactive_access_tokens.create(individual: true, guests: true)

    flash[:notice] = 'Created'
    redirect_back fallback_location: service_admin_panel_rooms_path
  end
end
