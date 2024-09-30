# frozen_string_literal: true
class Poll::Poll < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  self.table_name = 'polls'

  belongs_to :model, polymorphic: true
  belongs_to :poll_template, class_name: 'Poll::Template::Poll'
  has_many :options, class_name: 'Poll::Option'
  has_many :votes, class_name: 'Poll::Vote', through: :options
  has_one :organization, through: :poll_template
  has_one :user, through: :poll_template
  accepts_nested_attributes_for :options

  scope :enabled, -> { where(enabled: true) }

  after_commit :created_event, on: :create
  after_commit :setup_stop_job, unless: :manual_stop?

  def vote!(user, option_ids)
    if !multiselect && option_ids.is_a?(Array) && option_ids.count > 1
      raise 'Only one option is allowed to vote'
    end

    return if is_voted?(user.id)

    options_array = options.where(id: option_ids)
    options_array.find_each { |option| option.votes.find_or_create_by(user_id: user.id) }
    PollsChannel.broadcast('vote-poll', {
                             poll_id: id,
                             user_id: user.id,
                             model_id: model_id,
                             model_type: model_type,
                             votes_count: uniq_votes,
                             options: (hidden_results? ? [].to_json : options.to_json)
                           })
  end

  def is_voted?(user_id)
    return false unless user_id

    votes.exists?(user_id: user_id)
  end

  def uniq_votes
    votes.select(%(DISTINCT poll_votes.user_id)).count
  end

  def setup_stop_job
    ::PollJobs::StopPoll.perform_at(end_at, id)
  end

  def created_event
    PollsChannel.broadcast('add-poll', { poll_id: id, model_id: model_id, model_type: model_type })
  end

  def stop!
    return unless enabled?

    update!(enabled: false, end_at: Time.zone.now)
    PollsChannel.broadcast('stop-poll', { poll_id: id, model_id: model_id, model_type: model_type })
  end

  def start!
    return if enabled?

    model.polls.enabled.where.not(polls: { id: id }).find_each(&:stop!)
    self.start_at = Time.zone.now
    self.end_at = nil
    unless manual_stop
      self.end_at = start_at + duration.minutes
    end
    self.enabled = true
    save!
    PollsChannel.broadcast('start-poll', { poll_id: id, model_id: model_id, model_type: model_type })
  end
end
