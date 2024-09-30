# frozen_string_literal: true
class Presenter < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include ModelConcerns::HasVirtualFieldsThroughUserReference
  include ModelConcerns::ActiveModel::Extensions

  module LAST_SEEN_BECOME_PRESENTER_STEPS
    ABOUT = 'about'
    STEP1 = 'step1'
    STEP2 = 'step2'
    STEP3 = 'step3'
    DONE = 'wizard_complete'
    PRICING = 'pricing'

    ALL = [STEP1, STEP2, STEP3, DONE, PRICING].freeze

    OPTIONS_FOR_SELECT = [
      ['Personal Info', 'step1'],
      %w[Organization step2],
      ['First Channel', 'step3'],
      ['Wizard Completed', 'wizard_complete'],
      %w[Pricing pricing]
    ].freeze
  end

  validates :last_seen_become_presenter_step, inclusion: { in: LAST_SEEN_BECOME_PRESENTER_STEPS::ALL, allow_nil: true }
  validate :validate_ffmpegservice_account, on: :create

  has_many :issued_presenter_credits, dependent: :destroy
  has_many :presenter_credit_entries, dependent: :destroy

  has_many :channels, dependent: :destroy

  has_many :organizer_abstract_session_pay_promises, foreign_key: 'co_presenter_id', dependent: :destroy

  has_many :session_co_presenterships, dependent: :destroy
  has_many :channel_invited_presenterships, dependent: :destroy
  # has_many :sessions, through: :session_co_presenterships

  after_create :create_referral_code
  after_create :create_stripe_connect_account
  after_create :setup_affiliate_signature

  after_commit on: :create do
    user_reindex
  end

  validates :credit_line_amount, numericality: { greater_than_or_equal_to: 0 }

  # NOTE: "real" presenters are those who ever applied to become a presenter and/or has a channel
  # TODO: Presenters logic changed
  def self.real
    joins(:channels).where.not(last_seen_become_presenter_step: nil)
  end

  def self.has_channels
    sql = %{presenters.id IN (
        SELECT presenters.id FROM presenters JOIN channels ON channels.presenter_id = presenters.id
        UNION
        SELECT presenters.id FROM presenters JOIN channel_invited_presenterships ON channel_invited_presenterships.presenter_id = presenters.id)}
    where(sql).distinct
  end

  def self.without_channels
    joins(user: :organization).joins('LEFT JOIN channels ON channels.organization_id = organizations.id').where(channels: { id: nil })
  end

  # NOTE: do not remove it  because it is used in migration
  def create_referral_code
    u = user
    Retryable.retryable(tries: 7, on: ActiveRecord::RecordNotUnique) do
      ReferralCode.create!(user: u, code: rand(36**8).to_s(36)) # 4-characters long e.g. 's9fz'
    end
  end

  def object_label
    "Presenter Account of #{user.object_label}"
  end

  def full_name
    user.try(:full_name)
  end

  def co_presenter?(session)
    Rails.cache.fetch("#{__method__}/#{session.cache_key}/#{id}") do
      session_co_presenterships.where(session: session).present?
    end
  end

  def primary_presenter?(session)
    Rails.cache.fetch("#{__method__}/#{session.id}/#{id}") do
      session.organizer == user
    end
  end

  def presenter_credit_balance
    _key = "#{__method__}/#{cache_key}"

    Rails.cache.fetch(_key) do
      already_spent = presenter_credit_entries.pluck(:amount).sum

      # issued_presenter_credits.open.where.not(type: IssuedSystemCredit::Types::EARNED_CREDIT).pluck(:amount).sum - already_spent - credit_line_amount
      issued_presenter_credits.pluck(:amount).sum - already_spent
    end
  end

  def has_enough_credit?(charge_amount)
    (presenter_credit_balance - charge_amount) >= -credit_line_amount
  end

  def user_reindex
    user.multisearch_reindex
  end

  private

  def create_stripe_connect_account
    # result = Stripe::Account.create(
    #     type: 'custom',
    #     country: user.user_account.country,
    #     email: user.email
    # )
    #
    # StripeDb::ConnectAccount.create!({
    #                                      user_id: user.id,
    #                                      account_id: result.id,
    #                                      account_key: result.keys.secret,
    #                                      account_secret: result.keys.publishable
    #
    #                                 })
  end

  def validate_ffmpegservice_account
    # FIXME: is it ok @Max?
    return if Rails.env.test?

    unless FfmpegserviceAccount.main_free.not_assigned.find_by(user_id: nil)
      errors.add(:id, "Can't assign stream account")
    end
  end

  def setup_affiliate_signature
    user.setup_affiliate_signature
  end
end
