# frozen_string_literal: true

module ModelConcerns::OverlappedSessions
  extend ActiveSupport::Concern

  def overlapped_sessions(options = {})
    def self.relative_path
      nil
    end
    hours_per_page = 8

    start_at = if is_a?(Session)
                 self.start_at - pre_time.minutes
               else
                 self.start_at
               end
    start_at = options[:start_at].present? ? Time.parse(options[:start_at]) : start_at
    end_at   = options[:end_at].present?   ? Time.parse(options[:end_at])   : start_at + hours_per_page.hours

    organizer.participate_between_by_types(start_at, end_at).tap do |sessions|
      unless new_record?
        key = if is_a?(Session)
                :s_presenter
              else
                :gt_presenter
              end
        sessions[key].reject! { |s| s.id == id }
      end
      return [] unless sessions.any? { |_k, v| v.present? }

      sessions[:current] = [self]
    end.inject([]) do |res, (type, arr)|
      arr.each do |abstract_session|
        human_type = if type == :current
                       I18n.t('user_roles.current', model: I18n.t("activerecord.models.#{self.class.to_s.downcase}"))
                     else
                       I18n.t("user_roles.#{type}")
                     end
        res.push abstract_session.as_json({ only: %i[id start_at duration pre_time],
                                            methods: %i[always_present_title relative_path] }).merge({ type: type,
                                                                                                       human_type: human_type,
                                                                                                       class: self.class.to_s })
      end
      res
    end
  end
end
