# frozen_string_literal: true

module ModelConcerns::User::HasChannels
  extend ActiveSupport::Concern

  def channel
    owned_channels.first
  end

  def owned_and_invited_channels
    # channels that belong to user's organization
    # channels where user invited as presenter (except rejected invitation)
    Rails.cache.fetch("#{__method__}/#{cache_key}/#{Channel.count}/#{Organization.count}/#{ChannelInvitedPresentership.count}") do
      Channel.distinct.joins(%(LEFT JOIN organizations ON organizations.id = channels.organization_id))
             .joins(%(LEFT JOIN channel_invited_presenterships ON channel_invited_presenterships.channel_id = channels.id))
             .joins(%(LEFT JOIN presenters ON presenters.id = channel_invited_presenterships.presenter_id))
             .where(%(presenters.user_id = :user_id AND channel_invited_presenterships.presenter_id = presenters.id AND channel_invited_presenterships.status = :status OR organizations.user_id = :user_id),
                    status: :accepted, user_id: id)
    end
  end

  # TODO: Get rid of this
  def all_channels
    # channels that belong to user's presenter
    # channels that belong to user's organization
    # channels where user invited as presenter (except rejected invitation)
    Rails.cache.fetch("#{__method__}/#{cache_key}/#{Channel.count}/#{Organization.count}/#{OrganizationMembership.active.count}") do
      Channel.select('channels.*, COUNT(sessions.id) AS sessions_count, MIN(sessions.start_at) AS closest_session')
             .joins(%(LEFT JOIN organizations ON organizations.id = channels.organization_id))
             .joins(%(LEFT JOIN organization_memberships ON organization_memberships.organization_id = channels.organization_id))
             .joins(%(LEFT JOIN sessions ON sessions.channel_id = channels.id))
             .where(%(organization_memberships.user_id = :user_id AND organization_memberships.status = :member_status OR organizations.user_id = :user_id),
                    member_status: OrganizationMembership::Statuses::ACTIVE, user_id: id).group('channels.id')
    end
  end

  def owned_channels
    Rails.cache.fetch("#{__method__}/#{cache_key}/#{Channel.count}/#{Organization.count}") do
      Channel.not_archived.joins(%(LEFT JOIN organizations ON organizations.id = channels.organization_id))
             .where(organizations: { user_id: id }).distinct
    end
  end

  alias_method :channels, :owned_channels

  def presenter_users
    User.joins(presenter: { channel_invited_presenterships: :channel })
        .where(%(channels.id IN(SELECT channels.id FROM channels LEFT JOIN organizations ON organizations.id = channels.organization_id LEFT JOIN presenters ON presenters.id = channels.presenter_id WHERE organizations.user_id = :user_id OR presenters.user_id = :user_id)), user_id: id)
        .where(channel_invited_presenterships: { status: ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED }).distinct
  end

  def network_users
    User.select(%(DISTINCT users.*))
        .joins(%(LEFT JOIN presenters ON users.id = presenters.user_id))
        .joins(%(LEFT JOIN channel_invited_presenterships ON presenters.id = channel_invited_presenterships.presenter_id))
        .joins(%(LEFT JOIN channels ON channels.id = channel_invited_presenterships.channel_id OR channels.presenter_id = presenters.id))
        .joins(%(LEFT JOIN organizations ON organizations.id = channels.organization_id))
        .where(%(channel_invited_presenterships.channel_id IN (:channel_ids) AND channel_invited_presenterships.status = 'accepted' OR channels.id IN (:channel_ids) AND users.id = organizations.user_id), channel_ids: all_channels.pluck(:id))
        .where.not(id: id).order(:email)
  end

  def invited_channels
    owned_channels_ids = Channel.joins(:organization).where(organizations: { user_id: id }).pluck(:id)
    all_channels_with_credentials([::AccessManagement::Credential::Codes::START_SESSION]).where.not(id: owned_channels_ids)
  end

  def has_valid_channel?
    return false unless has_owned_channels?

    !!owned_channels.detect(&:valid?)
  end

  def has_owned_channels?
    persisted? && Rails.cache.fetch("#{__method__}/#{cache_key}/#{Channel.count}") do
      owned_channels.count.positive?
    end
  end

  def has_approved_channels?
    persisted? && Rails.cache.fetch("#{__method__}/#{cache_key}/#{Channel.count}") do
      owned_channels.approved.count.positive?
    end
  end

  def has_listed_channels?
    persisted? && Rails.cache.fetch("#{__method__}/#{cache_key}/#{Channel.count}") do
      publicly_visibile_to_general_audience.present?
    end
  end

  def has_invited_channels?
    return false unless presenter

    persisted? && Rails.cache.fetch("#{__method__}/#{cache_key}/#{Channel.count}") do
      invited_channels.exists?
    end
  end

  def has_any_channel?
    persisted? && Rails.cache.fetch("#{__method__}/#{cache_key}/#{Channel.count}") do
      Channel.joins(%(LEFT JOIN organizations ON organizations.id = channels.organization_id))
             .joins(%(LEFT JOIN channel_invited_presenterships ON channel_invited_presenterships.channel_id = channels.id))
             .joins(%(LEFT JOIN presenters ON presenters.id = channels.presenter_id OR presenters.id = channel_invited_presenterships.presenter_id))
             .where(%(presenters.user_id = :user_id AND channel_invited_presenterships.presenter_id = presenters.id AND channel_invited_presenterships.status != :status OR organizations.user_id = :user_id),
                    status: :rejected, user_id: id).uniq.count.positive?
    end
  end

  def channels_without_sessions
    Channel.joins(%(LEFT JOIN organizations ON organizations.id = channels.organization_id))
           .joins(%(LEFT JOIN channel_invited_presenterships ON channel_invited_presenterships.channel_id = channels.id))
           .joins(%(LEFT JOIN presenters ON presenters.id = channel_invited_presenterships.presenter_id))
           .joins(%(LEFT JOIN sessions ON sessions.channel_id = channels.id))
           .where(%(organizations.user_id = :user_id OR presenters.user_id = :user_id AND channel_invited_presenterships.presenter_id = presenters.id AND channel_invited_presenterships.status = :status),
                  status: :accepted, user_id: id).where(sessions: { id: nil }).uniq
  end

  def publicly_visibile_to_general_audience
    all_channels.where('channels.status = ? AND channels.archived_at IS NULL AND channels.listed_at IS NOT NULL',
                       Channel::Statuses::APPROVED)
  end

  def invitation_status_for(channel)
    return nil unless presenter

    Rails.cache.fetch("#{__method__}/#{id}/#{channel.id}") do
      presenter.channel_invited_presenterships.where(channel_id: channel.id).first.try(:status)
    end
  end
end
