# frozen_string_literal: true

module ModelConcerns::Organization::HasChannels
  extend ActiveSupport::Concern

  included do
    scope :with_channels, -> { joins(:channels) }
  end

  def channel
    all_channels.first
  end

  def all_channels
    # channels that belong to organization
    Rails.cache.fetch("organization/#{__method__}/#{id}/#{Channel.count}") do
      Channel.where(organization_id: id)
    end
  end

  def network_users
    User.select(%(DISTINCT users.*))
        .joins(%(LEFT JOIN presenters ON users.id = presenters.user_id))
        .joins(%(LEFT JOIN channel_invited_presenterships ON presenters.id = channel_invited_presenterships.presenter_id))
        .joins(%(LEFT JOIN channels ON channels.id = channel_invited_presenterships.channel_id OR channels.presenter_id = presenters.id))
        .joins(%(LEFT JOIN organizations ON organizations.id = channels.organization_id))
        .where(%{channel_invited_presenterships.channel_id IN (:channel_ids) AND channel_invited_presenterships.status = 'accepted' OR channels.id IN (:channel_ids) AND (presenters.id = channels.presenter_id OR users.id = organizations.user_id)}, channel_ids: all_channels.pluck(:id))
        .where.not(id: user_id).order(:email)
  end

  def has_approved_channels?
    @has_channels ||= persisted? && Rails.cache.fetch("organization/#{__method__}/#{id}/#{Channel.count}") do
      all_channels.approved.present?
    end
  end

  def has_listed_channels?
    @has_listed_channels ||= persisted? && Rails.cache.fetch("organization/#{__method__}/#{id}/#{Channel.count}") do
      publicly_visibile_to_general_audience.present?
    end
  end

  def has_any_channel?
    @has_any_channel ||= persisted? && Rails.cache.fetch("organization/#{__method__}/#{id}/#{Channel.count}") do
      all_channels.where.not(status: :rejected).present?
    end
  end

  def channels_without_sessions
    all_channels.joins(%(LEFT JOIN sessions ON sessions.channel_id = channels.id)).where(sessions: { id: nil }).uniq
  end

  def publicly_visibile_to_general_audience
    all_channels.where('channels.status = ? AND channels.archived_at IS NULL AND channels.listed_at IS NOT NULL',
                       Channel::Statuses::APPROVED)
  end

  def default_user_channel(user)
    Rails.cache.fetch("organization/#{__method__}/#{cache_key}/#{user&.cache_key}") do
      all_channels.visible_for_user(user).order(is_default: :desc, listed_at: :asc).first
    end
  end

  def channels_count
    Rails.cache.fetch("organization/#{__method__}/#{cache_key}") do
      channels.publicly_visibile_to_general_audience.count
    end
  end
end
