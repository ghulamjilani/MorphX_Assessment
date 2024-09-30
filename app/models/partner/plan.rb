# frozen_string_literal: true
class Partner
  class Plan < ::Partner::ApplicationRecord
    belongs_to :free_plan
    has_one :channel, through: :free_plan
    has_one :organization, through: :channel
    has_many :partner_subscriptions, class_name: 'Partner::Subscription', inverse_of: :partner_plan, foreign_key: :partner_plan_id, dependent: :destroy
    has_many :free_subscriptions, through: :partner_subscriptions

    before_validation :sanitize_name, if: :name_changed?
    before_validation :sanitize_description, if: :description_changed?

    validates :name, :foreign_plan_id, presence: true
    validates :foreign_plan_id, uniqueness: { scope: %i[free_plan_id enabled], if: :enabled?, message: 'has already been taken' }
    validates :name, uniqueness: { scope: %i[free_plan_id enabled], if: :enabled?, message: 'has already been taken' }

    scope :enabled, -> { where(enabled: true) }

    delegate :replays, :uploads, :livestreams, :interactives, :documents, :im_channel_conversation, to: :free_plan

    private

    def sanitize_name
      self.name = Sanitize.clean(
        name.to_s.html_safe,
        elements: %w[a b i br s u ul ol li p strong em],
        attributes: { a: %w[href target title] }.with_indifferent_access
      )
    end

    def sanitize_description
      self.description = Sanitize.clean(
        description.to_s.html_safe,
        elements: %w[a b i br s u ul ol li p strong em],
        attributes: { a: %w[href target title] }.with_indifferent_access
      )
    end
  end
end
