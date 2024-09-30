# frozen_string_literal: true

module ModelConcerns::Session::HasNonImmersiveDeliveryMethods
  extend ActiveSupport::Concern

  included do
    validate :livestream_costs_satisfies_system_parameters
    validate :recorded_costs_satisfies_system_parameters
  end

  def livestream_delivery_method?
    !livestream_purchase_price.nil?
  end

  def recorded_delivery_method?
    !recorded_purchase_price.nil?
  end

  def can_change_livestream_access_cost?
    return true unless persisted? # new, unsaved session
    return false if started?
    return false if active?
    return false if cancelled?

    payment_transactions.livestream_access.success.blank?
  end

  def can_change_livestream_purchase_price?
    can_change_livestream_access_cost?
  end

  def can_change_recorded_access_cost?
    return true unless persisted? # new, unsaved session
    return false if started?
    return false if active?
    return false if cancelled?

    payment_transactions.vod_access.success.blank?
  end

  def can_change_recorded_purchase_price?
    can_change_recorded_access_cost?
  end

  private

  # NOTE: if you update this logic, keep immersive_costs_satisfies_system_parameters in sync
  def livestream_costs_satisfies_system_parameters
    update_by_admin = persisted? && !update_by_organizer
    return if update_by_admin

    return if !livestream_purchase_price_changed? && !duration_changed?

    return if requested_free_session_satisfied_at.present? && Rails.env.test? # HACK: for :completely_free_session factory

    if livestream_access_cost.present? && livestream_access_cost < livestream_min_access_cost && !livestream_free
      errors.add(:livestream_access_cost, :greater_than_or_equal_to, count: livestream_min_access_cost)
    end
    if livestream_access_cost.present? && livestream_access_cost > ::SystemParameter.max_livestream_session_access_cost && !livestream_free
      errors.add(:livestream_access_cost, :less_than_or_equal_to,
                 count: ::SystemParameter.max_livestream_session_access_cost)
    end
  end

  def recorded_costs_satisfies_system_parameters
    update_by_admin = persisted? && !update_by_organizer
    return if update_by_admin

    return if !recorded_purchase_price_changed? && !duration_changed?

    if recorded_access_cost.present? && recorded_access_cost < recorded_min_access_cost && !recorded_free
      errors.add(:recorded_access_cost, :greater_than_or_equal_to, count: recorded_min_access_cost)
    end

    if recorded_access_cost.present? && recorded_access_cost > ::SystemParameter.max_recorded_session_access_cost && !recorded_free
      errors.add(:recorded_access_cost, :less_than_or_equal_to,
                 count: ::SystemParameter.max_recorded_session_access_cost)
    end
  end
end
