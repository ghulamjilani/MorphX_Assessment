# frozen_string_literal: true

module UpcomingSessionsHelper
  include JoinHelper
  include ActionView::Helpers::AssetUrlHelper

  def gon_session_attributes(session)
    return unless session

    immersive_interactor = ObtainImmersiveAccessToSession.new(session, current_user)
    livestream_interactor = ObtainLivestreamAccessToSession.new(session, current_user)

    data = {
      id: session.id,
      player_cover_url: session.player_cover_url,
      description: Sanitize.clean(session.always_present_description.to_s, Sanitize::Config::RELAXED),
      custom_description: session.custom_description_field_value,
      title: session.title,
      rating: session&.average(Session::RateKeys::QUALITY_OF_CONTENT)&.avg&.round(2)&.to_f,
      relative_path: session.relative_path,
      room_id: session.room.try(:id),
      slug: session.slug,
      total_participants_count: session.total_participants_count,
      # immersive_participants: session.immersive_participants.joins(:user).map do |p|
      #                           { relative_path: p.user.relative_path, avatar_url: p.user.small_avatar_url,
      #                             display_name: p.user.public_display_name }
      #                         end,
      # livestream_participants: session.livestream_participants.joins(:user).map do |p|
      #                            { relative_path: p.user.relative_path, avatar_url: p.user.small_avatar_url,
      #                              display_name: p.user.public_display_name }
      #                          end,
      views_count: session.views_count,
      duration: (session.duration % 30).zero? ? "#{session.duration.to_f / 60} hrs" : "#{session.duration} mins",
      allow_chat: session.allow_chat,
      autostart: session.autostart,

      can_cancel: can?(:cancel, session),
      can_clone: can?(:clone, session),
      can_edit: can?(:edit, session),
      can_like: !!current_user,
      can_publish: can?(:publish, session),
      can_request_another_time: can?(:request_another_time, session),
      can_share: can?(:share, session),
      can_rate: can?(:rate, session),

      cloneable_with_options: session.cloneable_with_options?,
      review: current_user ? session.reviews.where(user: current_user).first : nil,
      is_liked: current_user ? current_user.voted_as_when_voted_for(session) : false,
      likes_count: session.likes_count,
      like_path: session.toggle_like_relative_path,
      share_path: session.preview_share_relative_path,

      status: session.status,

      show_reviews: session.show_reviews,

      owner: session.organizer == current_user,
      organizer_id: session.organizer.id,
      organizer_name: session.organizer.public_display_name,
      organizer_path: session.organizer.relative_path,
      organizer_image: session.organizer.small_avatar_url,
      organizer_follow_path: session.organizer.toggle_follow_relative_path,
      organizer_followed: current_user&.following?(session.organizer),
      organizer_can_follow: current_user != session.organizer,

      immersive_purchase_price: session.immersive_purchase_price,
      livestream_purchase_price: session.livestream_purchase_price,
      recorded_purchase_price: session.recorded_purchase_price,

      replay_notify: if current_user && !session.recorded_purchase_price.nil?
                       PendingVodAvailabilityMembership.exists?(
                         abstract_session: session, user: current_user
                       )
                     else
                       false
                     end,
      replay_ready: (session.room && !session.recorded_purchase_price.nil?) ? session.room.vod_is_fully_ready : false,

      immersive_can_leave: can?(:opt_out_as_immersive_participant, session),
      immersive_obtained: current_user && (session.has_immersive_participant?(current_user.try(:participant_id)) || (current_user.presenter.present? && current_user.presenter.co_presenter?(session))),
      immersive_could_be_obtained_and_not_pending_invitee: immersive_interactor.could_be_obtained_and_not_pending_invitee?,
      immersive_can_have_free_trial: immersive_interactor.can_have_free_trial?,
      immersive_can_take_for_free: immersive_interactor.can_take_for_free?,
      immersive_could_be_purchased: immersive_interactor.could_be_purchased?,
      line_slots_left: session.line_slots_left,

      livestream_can_leave: can?(:opt_out_as_livestream_participant, session),
      livestream_obtained: current_user && ((current_user.participant.present? && session.livestream_participants.include?(current_user.participant)) || can?(
        :access_as_subscriber, session
      )),
      livestream_can_view_as_guest: !session.finished? && (can?(:view_livestream_as_guest,
                                                                session) || can?(:view_free_livestream, session)),
      livestream_could_be_obtained_and_not_pending_invitee: livestream_interactor.could_be_obtained_and_not_pending_invitee?,
      livestream_can_have_free_trial: livestream_interactor.can_have_free_trial?,
      livestream_can_take_for_free: livestream_interactor.can_take_for_free?,
      livestream_could_be_purchased: livestream_interactor.could_be_purchased?,

      # Array of delivery methods that user can obtain access to(purchase, etc.) (may contain all/some/none of the following values: :immersive, :livestream)
      available_delivery_methods: session.available_delivery_methods,

      # Array of delivery methods that user already has access to (may contain all/some/none of the following values: :immersive, :livestream)
      accessible_delivery_methods: accessible_delivery_methods(session),

      livestream_channel: (session.room&.id if can_see_session?(session)),
      public_livestream_channel: session.room&.id
    }.merge(commercials_attrs(session))
    # TODO: check this when PAUSE(brb) will be fixed
    room_member = begin
      session.room_members.find_by(abstract_user: session.room.presenter_user)
    rescue StandardError
      nil
    end
    data[:brb] =
      session.room && ((room_member.try(:mic_disabled) && room_member.try(:video_disabled)) || (session.room.try(:mic_disabled) && session.room.try(:video_disabled)))
    if current_user
      data[:quality_of_content_rate] =
        current_user.ratings_given.find_by(rateable: session, dimension: 'quality_of_content').try(:stars)
      data[:quality_of_content_rate_saved] =
        current_user.ratings_given.exists?(rateable: session, dimension: 'quality_of_content')
      data[:immerss_experience_rate] =
        current_user.ratings_given.find_by(rateable: session, dimension: 'immerss_experience').try(:stars)
      data[:immerss_experience_rate_saved] =
        current_user.ratings_given.exists?(rateable: session, dimension: 'immerss_experience')
      data[:overall_experience_comment] =
        session.reviews.where.not(overall_experience_comment: nil).find_by(user: current_user).try(:overall_experience_comment)
      data[:overall_experience_comment_saved] =
        session.reviews.where.not(overall_experience_comment: nil).exists?(user: current_user)
    end

    if session.room
      if session.finished?
        data[:finished] = session.finished?
        data[:cancelled] = session.cancelled?
        data[:stopped] = session.stopped?
      elsif session.upcoming?
        data[:upcoming] = true
        data[:started] = session.started?
        data[:running] = session.in_progress?
        data[:active] = session.room.active?
        data[:livestream_up] = session.started? && session.room.ffmpegservice_account.try(:stream_up?)
      end
    end
    if can?(:join_as_participant, session) || can?(:join_as_co_presenter, session)
      if session.room_members.find_by(abstract_user: current_user).try(:backstage?)
        data[:actual_start_at] = session.room.actual_start_at.to_i
        data[:pre_time] = session.pre_time
      end
    elsif can? :join_as_presenter, session
      data[:actual_start_at] = session.room.actual_start_at.to_i
      data[:pre_time] = session.pre_time
    end
    data[:start_at] = session.start_at.to_i

    if (can?(:join_as_livestreamer,
             session) || can?(:view_free_livestream,
                              session)) && (session.started? && session.room && session.in_progress? && session.room.ffmpegservice_account.try(:stream_up?))
      sa = session.room.ffmpegservice_account
      data[:stream_url] = sa.stream_m3u8_url
      data[:upcoming] = false
      data[:running] = true
    end

    data
  end

  def gon_channel_attributes(channel)
    return unless channel

    {
      id: channel.id,
      title: channel.title,
      description: channel.description,
      image_url: channel.organization ? channel.organization.small_logo_url : channel.organizer.avatar_url,
      logo_url: channel.logo_url,

      slug: channel.slug,
      owner: channel.organizer == current_user,
      relative_path: channel.relative_path,
      subscribe_path: channel.toggle_subscribe_relative_path,
      subscribed: current_user&.fast_following?(channel),
      subscribers_count: channel.count_user_followers
    }
  end

  def gon_organization_attributes(organization)
    return unless organization

    {
      id: organization.id,
      title: organization.title
    }
  end

  def gon_organizer_attributes(user)
    return unless user

    {
      id: user.id,
      name: user.public_display_name,
      path: user.relative_path,
      image: user.small_avatar_url,
      followed: current_user&.following?(user),
      can_follow: current_user != user
    }
  end

  def gon_replay_attributes(replay)
    session = replay.session
    interactor = ObtainRecordedAccessToSession.new(session, current_user)
    {
      id: replay.id,
      title: session.title,
      description: Sanitize.clean(replay.always_present_description.to_s, Sanitize::Config::RELAXED),
      custom_description: session.custom_description_field_value,
      path: replay.relative_path,
      image: (replay.poster_url || asset_url(session.channel.image_preview_url)),
      price: session.recorded_purchase_price,
      views_count: session.views_count,
      cropped_start_at: replay.cropped_start_at,
      rating: session&.channel&.average(Session::RateKeys::QUALITY_OF_CONTENT)&.avg&.round(2).to_f,

      owner: session.organizer == current_user,
      organizer_id: session.organizer.id,
      organizer_name: session.organizer.public_display_name,
      organizer_path: session.organizer.relative_path,
      organizer_image: session.organizer.small_avatar_url,
      organizer_follow_path: session.organizer.toggle_follow_relative_path,
      organizer_followed: current_user&.following?(session.organizer),
      organizer_can_follow: current_user != session.organizer,

      is_free: session.recorded_purchase_price&.zero?,
      can_like: !!current_user,
      can_rate: can?(:rate, session),
      is_liked: current_user ? current_user.voted_as_when_voted_for(session) : false,
      likes_count: session.likes_count,
      like_path: session.toggle_like_relative_path,
      can_share: can?(:share, session),
      share_path: session.preview_share_relative_path(vod_id: replay.id),

      video_url: (can?(:see_full_version_video, session) ? replay.url : replay.preview_url),
      replay: true,

      obtained: can?(:opt_out_as_recorded_member, session) || can?(:access_replay_as_subscriber, session),
      can_take_for_free: interactor.can_take_for_free?,
      could_be_purchased: interactor.could_be_purchased?,
      obtain_non_free_access_title: interactor.obtain_non_free_access_title,
      purchase_path: preview_purchase_channel_session_path(session.slug,
                                                           type: (session.recorded_purchase_price&.zero? ? ObtainTypes::FREE_VOD : ObtainTypes::PAID_VOD)),
      playlist_attrs: if session.allow_chat?
                        Playlist.new(user: current_user).tap do |pl|
                          pl.add_video(replay)
                        end.as_json[0]
                      else
                        {}
                      end
    }.merge(commercials_attrs(session))
  end

  def gon_recording_attributes(recording)
    return unless recording

    interactor = ObtainAccessToRecording.new(recording, current_user)
    {
      id: recording.id,
      title: recording.title,
      description: recording.description,
      path: recording.relative_path,
      image: recording.poster_url,
      price: recording.purchase_price.to_f,
      views_count: recording.views_count,
      rating: recording&.channel&.average(Session::RateKeys::QUALITY_OF_CONTENT)&.avg&.round(2).to_f,

      is_free: recording.purchase_price.to_f.zero?,
      quality_of_content_rate: current_user && current_user.ratings_given.find_by(rateable: recording,
                                                                                  dimension: 'quality_of_content').try(:stars),
      can_share: can?(:share, recording),
      share_path: recording.preview_share_relative_path,
      can_rate: can?(:rate, recording),

      owner: recording.organizer == current_user,
      video_url: (can?(:see_recording, recording) ? recording.url : recording.preview_url),
      replay: false,
      organizer_id: recording.organizer.id,
      organizer_name: recording.organizer.public_display_name,
      organizer_path: recording.organizer.relative_path,
      organizer_image: recording.organizer.small_avatar_url,
      organizer_follow_path: recording.organizer.toggle_follow_relative_path,
      organizer_followed: current_user&.following?(recording.organizer),
      organizer_can_follow: current_user != recording.organizer,

      obtained: can?(:opt_as_recording_participant, recording),
      can_see_recording: can?(:see_recording, recording),
      can_take_for_free: interactor.can_take_for_free?,
      could_be_purchased: interactor.can_purchase?,
      obtain_non_free_access_title: interactor.obtain_non_free_access_title,
      purchase_path: preview_purchase_recording_path(recording,
                                                     type: (recording.free? ? ObtainTypes::FREE_RECORDING : ObtainTypes::PAID_RECORDING))
    }
  end

  def url_attrs(session)
    room = session.room

    if session.status == Session::Statuses::REQUESTED_FREE_SESSION_REJECTED || room.blank?
      return {}
    end

    if session.in_progress?
      status = 'running'
      text = 'Live now'
    elsif session.running?
      status = 'started'
      text = 'Starts soon'
    elsif session.cancelled?
      status = 'cancelled'
      text = 'Cancelled'
    elsif session.finished?
      status = 'completed'
      text = 'Completed'
    else
      status = 'upcoming'
      text = 'Starts in:'
    end

    if can?(:join_as_participant, session) || can?(:join_as_co_presenter, session)
      start_at = session.room_members.find_by(abstract_user: current_user).try(:backstage?) ? room.actual_start_at.to_i : session.start_at.to_i
      type = 'immersive'
      presenter = false
    elsif can?(:join_as_presenter, session)
      start_at = room.actual_start_at.to_i
      type = 'immersive'
      presenter = true
    elsif can?(:join_as_livestreamer, session) || can?(:view_free_livestream, session)
      start_at = session.start_at.to_i
      type = 'livestream'
      presenter = false
    else
      start_at = session.start_at.to_i
      type = 'in_progress'
      presenter = false
    end
    if presenter || can?(:join_as_participant, session) || can?(:join_as_co_presenter, session)
      onclick_value = join_as_participant_onclick_value(room, (type == 'immersive'), nil)
    elsif can?(:view_free_livestream, session)
      onclick_value = ''
    elsif %w[in_progress livestream].include?(type)
      onclick_value = 'return false;'
    end
    text = 'Join' if type == 'immersive' && %w[started running].include?(status)

    {
      id: session.id,
      onclick: onclick_value,
      presenter: presenter,
      room_id: room.try(:id),
      start_at: start_at,
      status: status,
      active: session.room&.active?,
      livestream_up: session.started? && session.room && session.room.ffmpegservice_account.try(&:stream_up?),
      text: text,
      type: type
    }
  end

  private

  def commercials_attrs(session)
    record =
      if session.commercials_url && session.commercials_duration && session.commercials_mime_type
        session
      else
        session.channel
      end
    {
      commercials_url: record.commercials_url,
      commercials_duration: record.commercials_duration,
      commercials_mime_type: record.commercials_mime_type
    }
  end

  def accessible_delivery_methods(session)
    assessible_methods = []
    assessible_methods << :livestream if can_see_session? session
    assessible_methods << :immersive if can_participate? session
    assessible_methods
  end

  def can_see_session?(session)
    can?(:view_livestream_as_guest, session) ||
      can?(:view_free_livestream, session) ||
      can?(:join_as_livestreamer, session) ||
      can?(:access_as_subscriber, session)
  end

  def can_participate?(session)
    can?(:join_as_presenter, session) ||
      can?(:join_as_co_presenter, session) ||
      can?(:join_as_participant, session)
  end
end
