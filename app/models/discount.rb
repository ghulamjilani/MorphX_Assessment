# frozen_string_literal: true
# :name - имя(код) дисконта, например OCT30
# :target_type - тип покупаемого доступа
#   * Livestream - применять только к покупке лайвстрима, в target_ids указать id сессии(й) или null(любая сессия с Livestream)
#   * Immersive - применять только к покупке интерактива, в target_ids указать id сессии(й) или null(любая сессия с Immersive)
#   * Replay - применять только к покупке реплея, в target_ids указать id сессии(й) или null(любая сессия с Replay)
#   * Recording - применять только к покупке рекординга(видео с гугл диска), в target_ids указать id рекординга(ов) или null(любой Recording)
#   * Session - любой тип сессии [Livestream, Immersive, Replay],  в target_ids указать id сессии(й))
#   * Channel - все покупки в контексте определенного канала, в target_ids указать id канала(ов))
# :target_ids - айдишники сессиий, видео или каналов;
#   * целые числа через запятую, например 4116,234
#   * null - применяется ко всем сущностям из target_type
# :usage_count_per_user - сколько раз один юзер может использовать;
#   * целое число, значение больше 0
#   * 0, null - безлимит
# :usage_count_total - сколько раз купон может использован вообще;
#   * целое число, значение больше 0
#   * 0, null - безлимит
# :expires_at - до каких пор валидный;
#   * дата+время - временный
#   * null - перманентный
# :min_amount_cents - минимальная цена покупки в центах, к которой может применяться данный купон;
#   * целое число, значение больше 0
#   * 0, null - любая цена
# :amount_off_cents - скидка в центах, целое число >= 0
# :percent_off_precise - cкидка в %, число с плавающей точкой, от 0.1
# :is_valid - активный или неактивный

class Discount < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  TYPES = %w[Livestream Immersive Replay Recording Session Channel].freeze
  LIVESTREAM_TYPES = %w[Livestream Session Channel].freeze
  IMMERSIVE_TYPES = %w[Immersive Session Channel].freeze
  REPLAY_TYPES = %w[Replay Session Channel].freeze
  RECORDING_TYPES = %w[Recording Channel].freeze

  SESSION_TYPES = %w[Livestream Immersive Replay].freeze

  serialize :target_ids, Array

  validates :amount_off_cents, presence: { if: ->(d) { d.percent_off_precise.nil? } }
  validates :percent_off_precise, presence: { if: ->(d) { d.amount_off_cents.nil? } }
  validates :target_type, inclusion: { in: TYPES }

  has_many :discount_usages

  def valid_for?(item, type, user)
    # discount is not active
    unless active?
      update(is_valid: false)
      return false
    end

    # usage_count_per_user present & user already applied this discount
    return false if usage_count_per_user&.positive? && usage_count_per_user == discount_usages.where(user_id: user.id).count

    # usage_count_total present & usage limit reached
    if usage_count_total&.positive? && usage_count_total == discount_usages.count
      update(is_valid: false)
      return false
    end

    # for whole channel && target ids not equal
    return false if target_type == 'Channel' && target_ids.present? && target_ids.map(&:to_s).exclude?(item.channel_id.to_s)

    if SESSION_TYPES.include?(type)
      # not for session
      return false if target_type == 'Recording'
      # not a session
      return false unless item.is_a?(Session)
    end

    if type == 'Recording'
      # not for recording
      return false if target_type != 'Recording'
      # not a recording
      return false unless item.is_a?(Recording)
    end

    case type
    when 'Livestream'
      return false unless LIVESTREAM_TYPES.include?(target_type)
      return false if %w[Livestream
                         Session].include?(target_type) && target_ids.present? && target_ids.map(&:to_s).exclude?(item.id.to_s)
      return false if item.livestream_purchase_price < (amount_off_cents.to_f / 100)
    when 'Immersive'
      return false unless IMMERSIVE_TYPES.include?(target_type)
      return false if %w[Immersive
                         Session].include?(target_type) && target_ids.present? && target_ids.map(&:to_s).exclude?(item.id.to_s)
      return false if item.immersive_purchase_price < (amount_off_cents.to_f / 100)
    when 'Replay'
      return false unless REPLAY_TYPES.include?(target_type)
      return false if %w[Replay
                         Session].include?(target_type) && target_ids.present? && target_ids.map(&:to_s).exclude?(item.id.to_s)
      return false if item.recorded_purchase_price < (amount_off_cents.to_f / 100)
    when 'Recording'
      return false if target_type == 'Recording' && target_ids.present? && target_ids.map(&:to_s).exclude?(item.id.to_s)
      return false if item.purchase_price < (amount_off_cents.to_f / 100)
    end
    true
  end

  def active?
    is_valid? && (expires_at.nil? || expires_at > Time.now)
  end
end
