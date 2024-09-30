# frozen_string_literal: true

module ModelConcerns::Session::Recurring
  extend ActiveSupport::Concern
  extend ActsAsTree::TreeWalker
  DAYS_OF_WEEK = %w[sunday monday tuesday wednesday thursday friday saturday].freeze

  included do
    acts_as_tree foreign_key: :recurring_id
    serialize :recurring_settings, ActiveSupport::HashWithIndifferentAccess

    before_validation :clear_recurring_limits
    validate :recurring_limits, if: -> { recurring_settings.present? }
  end

  def recurring_setting_active
    'checked' if recurring_settings[:active]
  end

  def recurring_setting_until_date
    'checked' if recurring_settings[:until] == 'date'
  end

  def recurring_setting_until_occurrence
    'checked' if recurring_settings[:until] == 'occurrence' || recurring_settings[:until].nil?
  end

  def recurring_setting_date
    recurring_settings[:date] ? recurring_settings[:date] : Date.tomorrow.strftime('%m/%d/%Y')
  end

  def recurring_setting_occurrence
    recurring_settings[:occurrence].presence || 1
  end

  def has_recurring?
    recurring_id.present? || children.present?
  end

  def unchain!
    if (ch = children.first)
      ch.update_columns(recurring_id: recurring_id)
    end
    update_columns(recurring_id: nil, recurring_settings: nil)
  end

  def unchain_all!
    recurring_tree.each do |session|
      session.update_columns(recurring_id: nil, recurring_settings: nil)
    end
  end

  DAYS_OF_WEEK.each do |day|
    define_method("recurring_setting_day_#{day}") do
      return 'checked' if recurring_settings[:days]&.include?(day)

      if recurring_settings[:days].blank? && Time.now.strftime('%A').downcase == day
        'checked'
      end
    end
  end

  def as_json(options)
    hash = {
      recurring_setting_active: recurring_setting_active,
      recurring_setting_until_occurrence: recurring_setting_until_occurrence,
      recurring_setting_until_date: recurring_setting_until_date,
      recurring_setting_date: recurring_setting_date,
      recurring_setting_occurrence: recurring_setting_occurrence
    }
    DAYS_OF_WEEK.each do |day|
      hash.merge!({ "recurring_setting_day_#{day}" => send("recurring_setting_day_#{day}") })
    end
    super(options).merge(hash)
  end

  private

  def recurring_tree
    current_session = root
    rt = []
    while current_session.present?
      rt << current_session
      current_session = current_session.children.first
    end
    rt
  end

  def clear_recurring_limits
    if recurring_settings[:active] != 'on'
      self.recurring_settings = ActiveSupport::HashWithIndifferentAccess.new
    end
  end

  def recurring_limits
    unless ['on', nil].include?(recurring_settings[:active])
      errors.add(:recurring_settings, 'recurring -> active has wrong value')
    end
    unless %w[occurrence date].include?(recurring_settings[:until])
      errors.add(:recurring_settings, 'recurring -> until has wrong value')
    end

    if recurring_settings[:until] == 'date'
      begin
        date = Date.strptime(recurring_settings[:date], '%m/%d/%Y')
        unless date >= Date.tomorrow && date <= 3.month.from_now.to_date
          errors.add(:recurring_settings, 'recurring -> date has wrong date')
        end
      rescue StandardError => e
        errors.add(:recurring_settings, e.message)
      end
    end

    if recurring_settings[:until] == 'occurrence' && !(1..89).cover?(recurring_settings[:occurrence].to_i)
      errors.add(:recurring_settings, 'recurring -> occurrence has wrong value')
    end

    if recurring_settings[:days].present?
      if recurring_settings[:days].is_a?(Array)
        unless recurring_settings[:days].all? { |v| DAYS_OF_WEEK.include?(v) }
          errors.add(:recurring_settings, 'recurring -> days has wrong value')
        end
      else
        errors.add(:recurring_settings, 'recurring -> days has wrong value')
      end
    else
      errors.add(:recurring_settings, 'recurring -> days has wrong value')
    end
  end
end
