# frozen_string_literal: true

class Playlist
  attr_reader :playlist

  def initialize(user:)
    @playlist = []
    @user = user
  end

  def add_recording(recording, primary: false)
    s = Subscription.where(channel_id: recording.channel_id).preload(:plans).first
    plan_price = s ? s.plans.active.pluck(:amount).map(&:to_f).min : nil
    @playlist.push(
      {
        id: recording.id,
        type: 'recording',
        description: recording.description,
        playback_url: (can_see_recording?(recording) ? recording.url : recording.preview_url),
        is_purchased: can_see_recording?(recording),
        recorded_purchase_price: recording.purchase_price,
        subscription_price: plan_price,
        is_paid: !recording.purchase_price.to_f.zero?,
        absolute_path: recording.absolute_path,
        title: recording.title,
        views_count: recording.views_count,
        rating: begin
          recording.channel.average(Session::RateKeys::QUALITY_OF_CONTENT).avg.round(2)
        rescue StandardError
          0
        end.to_f,
        created_at: recording.created_at.utc,
        poster_url: recording.poster_url || recording.channel.image_preview_url,
        position: "#{position_prefix(recording, primary)}#{recording.created_at.to_i}".to_i,
        chat_channel_id: '',
        is_chat_available: false,
        presenter_id: recording.organizer.id,
        user_full_name: recording.organizer.full_name,
        user_avatar_url: recording.organizer.avatar_url,
        share_url: recording.short_url,
        share_image_url: recording.share_image_url,
        only_ppv: recording.only_ppv,
        only_subscription: recording.only_subscription
      }.merge(commercials_attrs(recording)).merge(channel_attrs(recording)).merge(company_attrs(recording))
    )
  end

  def add_video(video, primary: false)
    im_conversation = video.session.im_conversation
    s = Subscription.where(channel_id: video.session.channel_id).preload(:plans).first
    plan_price = s ? s.plans.active.pluck(:amount).map(&:to_f).min : nil
    @playlist.push(
      {
        id: video.id,
        type: 'video',
        description: video.always_present_description,
        custom_description: video.session.custom_description_field_value,
        playback_url: video_playback_url(video),
        is_purchased: can_see_video?(video),
        recorded_purchase_price: video.session.recorded_purchase_price,
        subscription_price: plan_price,
        is_paid: !video.session.recorded_purchase_price.to_f.zero?,
        absolute_path: video.absolute_path,
        title: video.always_present_title,
        views_count: video.views_count,
        rating: session_rating(video.session).round(2),
        created_at: video.created_at.utc,
        poster_url: video.poster_url || video.session.channel.image_preview_url,
        position: "#{position_prefix(video, primary)}#{video.session.start_at.to_i}".to_i,
        is_chat_available: video.session.allow_chat? && im_conversation&.messages&.exists?,
        presenter_id: video.session.room&.presenter_user_id,
        user_full_name: video.session.user.full_name,
        user_avatar_url: video.session.user.avatar_url,
        start_at: video.session.start_at.utc,
        share_url: video.short_url,
        share_image_url: video.share_image_url,
        only_ppv: video.only_ppv,
        only_subscription: video.only_subscription
      }.merge(commercials_attrs(video.session)).merge(channel_attrs(video.session)).merge(company_attrs(video.session))
    )
  end

  def add_session(session, primary: false)
    s = Subscription.where(channel_id: session.channel_id).preload(:plans).first
    plan_price = s ? s.plans.active.pluck(:amount).map(&:to_f).min : nil
    @playlist.push(
      {
        id: session.id,
        type: 'session',
        duration: session.duration,
        description: session.always_present_description,
        custom_description: session.custom_description_field_value,
        playback_url: video_playback_url(session&.primary_record),
        is_purchased: can_see_session?(session),
        livestream_url: session_playback_url(session),
        livestream_channel: session.room.public_livestream_channel,
        private_livestream_channel: private_livestream_channel(session),
        livestream_purchase_price: session.livestream_purchase_price,
        livestream_free: session.livestream_free,
        is_livestream: !session.livestream_purchase_price.nil?,
        immersive_purchase_price: session.immersive_purchase_price,
        immersive_free: session.immersive_free,
        is_immersive: !session.immersive_purchase_price.nil?,
        immersive_spots_left: session.interactive_participants_count,
        immersive_spots_total: session.max_number_of_immersive_participants,
        subscription_price: plan_price,
        is_paid: !session.livestream_purchase_price.to_f.zero?,
        absolute_path: session.absolute_path,
        user_full_name: session.user.full_name,
        user_avatar_url: session.user.avatar_url,
        start_at: session.start_at.utc,
        is_finished: session.finished?,
        is_room_active: session.room.active?,
        title: session.title,
        views_count: session.room&.watchers_count,
        participants_count: session.total_participants_count,
        rating: session_rating(session).round(2),
        poster_url: session.small_cover_url,
        player_cover_url: session.player_cover_url,
        position: "#{position_prefix(session, primary)}#{session.room.actual_start_at.to_i}".to_i,
        has_chat: session.allow_chat?,
        webrtcservice_channel_id: session.webrtcservice_channel_id,
        share_url: session.short_url,
        share_image_url: session.share_image_url,
        only_ppv: session.only_ppv,
        only_subscription: session.only_subscription
      }.merge(commercials_attrs(session)).merge(channel_attrs(session)).merge(company_attrs(session))
    )
  end

  def as_json(*)
    @playlist.as_json
  end

  private

  def private_livestream_channel(session)
    if can_see_session?(session)
      session.room.livestream_channel
    end
  end

  # Sets a position prefix that will be used to determine order in which records should go in playlist.
  # It supposed to come in ascending order.
  # {Session} has higher priority - prepends with '11' in case if it is additional session for playlist. It
  # prepends with '10' if this is a session that user is currently sharing.
  # Same thing is about {Video}, but with one exception - videos(replays) has lower priority than sessions, thus videos
  # should be prepended with '21' - for additional videos and '20' for video which user is currently sharing.
  def position_prefix(record, primary)
    prepend_with = record.is_a?(Session) ? '11' : '21'
    prepend_with = "#{prepend_with[0]}0" if primary
    prepend_with
  end

  def video_playback_url(video)
    return unless video

    can_see_video?(video) ? video.url : video.preview_url
  end

  def session_playback_url(session)
    return unless session&.ffmpegservice_account

    if can_see_session?(session)
      session.ffmpegservice_account.stream_m3u8_url
    else
      session.ffmpegservice_account.stream_stub_url
    end
  end

  def can_see_session?(session)
    session_ability = AbilityLib::SessionAbility.new(@user)
    session_ability.can?(:view_livestream_as_guest, session) ||
      session_ability.can?(:view_free_livestream, session) ||
      session_ability.can?(:join_as_livestreamer, session) ||
      session_ability.can?(:access_as_subscriber, session)
  end

  def can_see_video?(video)
    AbilityLib::SessionAbility.new(@user).can?(:see_full_version_video, video.session)
  end

  def can_see_recording?(recording)
    AbilityLib::RecordingAbility.new(@user).can?(:see_recording, recording)
  end

  def session_rating(session)
    session.average(Session::RateKeys::QUALITY_OF_CONTENT).avg.round(2)
  rescue StandardError
    0.0
  end

  def commercials_attrs(session)
    record =
      if session.respond_to?(:commercials_url) && session.commercials_url && session.commercials_duration && session.commercials_mime_type
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

  def channel_attrs(session)
    {
      channel_title: session.channel.title,
      channel_url: session.channel.absolute_path,
      channel_logo: session.channel.logo_url,
      channel_cover: session.channel.image_gallery_url
    }
  end

  def company_attrs(session)
    if session.channel.organization
      {
        compamy_title: session.channel.organization.name,
        compamy_url: session.channel.organization.absolute_path,
        compamy_logo: session.channel.organization.logo_url
      }
    else
      {}
    end
  end
end
