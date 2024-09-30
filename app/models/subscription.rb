# frozen_string_literal: true
class Subscription < ActiveRecord::Base
  belongs_to :channel
  belongs_to :user
  has_many :plans, lambda {
                     order('stripe_plans.id ASC')
                   }, class_name: 'StripeDb::Plan', foreign_key: :channel_subscription_id, dependent: :destroy
  has_many :stripe_subscriptions, class_name: 'StripeDb::Subscription', through: :plans

  validates :user_id, :channel_id, :description, presence: true
  validates :enabled, uniqueness: { scope: :channel_id }, if: :enabled?

  accepts_nested_attributes_for :plans
end
