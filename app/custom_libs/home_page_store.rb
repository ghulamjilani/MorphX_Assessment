# frozen_string_literal: true

# NOTE: this store's fetch methods are meant to be called in certain order to work properly
# call it in this order for proper fetching:
# #brand_new
# #most_popular
# #free
# #featured
class HomePageStore
  def initialize(current_user, limit = 15)
    @current_user = current_user
    @limit = limit
  end

  # Recordings
  def recordings
    @recordings ||= Recording.for_homepage
                             .order(Arel.sql('CASE WHEN ((recordings.promo_weight <> 0 AND recordings.promo_start IS NULL AND recordings.promo_end IS NULL) OR (recordings.promo_start < now() AND now() < recordings.promo_end)) THEN 100 + recordings.promo_weight ELSE 0 END ASC, recordings.created_at DESC'))
                             .limit(@limit).preload(:channel)
  end

  # Replays
  def replays
    @replays ||= Video.with_new_vods.not_fake.for_home_page
                      .joins({ session: :channel }, :user).where.not(channels: { listed_at: nil })
                      .where(channels: { status: :approved, archived_at: nil, fake: false }, users: { fake: false })
                      .order(Arel.sql('CASE WHEN ((videos.promo_weight <> 0 AND videos.promo_start IS NULL AND videos.promo_end IS NULL) OR (videos.promo_start < now() AND now() < videos.promo_end)) THEN 100 + videos.promo_weight ELSE 0 END ASC, videos.created_at DESC'))
                      .limit(@limit).preload(session: [{ presenter: { user: :image } }, :channel])
  end

  # Channels
  def channels
    @channels ||= Channel.with_user.listed.approved.not_archived.for_home_page.not_fake.where(users: { fake: false })
                         .order(Arel.sql('CASE WHEN ((channels.promo_weight <> 0 AND channels.promo_start IS NULL AND channels.promo_end IS NULL) OR (channels.promo_start < now() AND now() < channels.promo_end)) THEN 100 + channels.promo_weight ELSE 0 END ASC, channels.created_at ASC'))
                         .limit(@limit)
  end

  # Creators
  def creators
    @creators ||= User.joins(:image).joins(:presenter).where(show_on_home: true, fake: false).limit(@limit)
                      .order(Arel.sql('CASE WHEN ((users.promo_weight <> 0 AND users.promo_start IS NULL AND users.promo_end IS NULL) OR (users.promo_start < now() AND now() < users.promo_end)) THEN 100 + users.promo_weight ELSE 0 END ASC, users.created_at ASC'))
  end

  # Sessions
  def live_now
    @live_now ||= Session.joins(:channel).joins(presenter: :user)
                         .live_now.not_cancelled.for_user_with_age(@current_user).where.not(channels: { listed_at: nil })
                         .where(channels: { status: Channel::Statuses::APPROVED, archived_at: nil, fake: false })
                         .where(sessions: { fake: false, show_on_home: true, private: false, status: :published,
                                            stopped_at: nil })
                         .where(users: { fake: false })
                         .where('sessions.immersive_purchase_price IS NOT NULL OR sessions.livestream_purchase_price IS NOT NULL')
                         .order(Arel.sql('CASE WHEN ((sessions.promo_weight <> 0 AND sessions.promo_start IS NULL AND sessions.promo_end IS NULL) OR (sessions.promo_start < now() AND now() < sessions.promo_end)) THEN 100 + sessions.promo_weight ELSE 0 END DESC, sessions.start_at ASC'))
                         .limit(@limit).preload(:channel)
  end

  def upcoming
    # exclude_ids = live_now.map(&:id)
    # exclude_ids = [-1] if exclude_ids.blank?
    @upcoming ||= Session.joins(:channel).joins(presenter: :user)
                         .upcoming.not_cancelled.for_user_with_age(@current_user).where.not(channels: { listed_at: nil })
                         .where(channels: { status: Channel::Statuses::APPROVED, archived_at: nil, fake: false })
                         .where(sessions: { fake: false, show_on_home: true, private: false, status: :published,
                                            stopped_at: nil })
                         .where(users: { fake: false })
                         .where('sessions.immersive_purchase_price IS NOT NULL OR sessions.livestream_purchase_price IS NOT NULL')
                         .order(Arel.sql('CASE WHEN ((sessions.promo_weight <> 0 AND sessions.promo_start IS NULL AND sessions.promo_end IS NULL) OR (sessions.promo_start < now() AND now() < sessions.promo_end)) THEN 100 + sessions.promo_weight ELSE 0 END DESC, sessions.start_at ASC'))
                         .limit(15).preload(:channel) # FIXME: use @limit when we decide how to build query for homepage
  end

  def brands
    @brands ||= Channel.where(display_in_coming_soon_section: true).order(brand_weight: :desc).limit(15)
  end

  def companies
    @companies ||= Organization.where(show_on_home: true, fake: false)
                               .order(Arel.sql('CASE WHEN ((organizations.promo_weight <> 0 AND organizations.promo_start IS NULL AND organizations.promo_end IS NULL) OR (organizations.promo_start < now() AND now() < organizations.promo_end)) THEN 100 + organizations.promo_weight ELSE 0 END ASC, organizations.created_at ASC'))
                               .limit(@limit)
  end

  def all_upcoming
    @all_upcoming ||= Session.joins(:channel).joins(presenter: :user)
                             .upcoming.not_cancelled.for_user_with_age(@current_user).where.not(channels: { listed_at: nil })
                             .where(channels: { status: Channel::Statuses::APPROVED, archived_at: nil, fake: false })
                             .where(sessions: { fake: false, private: false, status: :published, stopped_at: nil })
                             .where(users: { fake: false })
                             .where('sessions.immersive_purchase_price IS NOT NULL OR sessions.livestream_purchase_price IS NOT NULL')
  end

  def all_channels
    @all_channels ||= Channel.with_user.listed.approved.not_archived.not_fake.where(users: { fake: false })
  end

  def all_creators
    @all_creators ||= User.joins(:image).joins(:presenter).where(fake: false)
  end

  def all_replays
    @all_replays ||= Video.with_new_vods.not_fake
                          .joins({ session: :channel }, :user).where.not(channels: { listed_at: nil })
                          .where(channels: { status: :approved, archived_at: nil, fake: false }, users: { fake: false })
  end

  def all_recordings
    @all_recordings ||= Recording.available.visible
  end

  def all_companies
    @all_companies ||= Organization.where(fake: false)
  end
end
