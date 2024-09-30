# frozen_string_literal: true

# NOTE: order of method calls is important. #featured has higher priority therefore must be called first
# #featured
# #brand_new
class HomePagePresentersStore
  attr_accessor :raw_featured, :raw_on_demand

  def initialize(limit = 15)
    @limit = limit
  end

  def pre_fetch_featured_and_on_demand
    @raw_featured ||= User.joins(:image).joins(:presenter)
                          .joins(%(LEFT JOIN organizations ON organizations.user_id = users.id))
                          .joins(%(LEFT JOIN channels ON channels.organization_id = organizations.id OR channels.presenter_id = presenters.id))
                          .where(%(presenters.featured IS TRUE))
                          .where(%(channels.status = ? AND channels.listed_at IS NOT NULL AND channels.archived_at IS NULL), Channel::Statuses::APPROVED)
                          .not_fake.for_home_page.limit(@limit).uniq

    @raw_on_demand ||= User.joins(:image).joins(:user_account).joins(:presenter)
                           .joins(%(LEFT JOIN organizations ON organizations.user_id = users.id))
                           .joins(%(LEFT JOIN channels ON channels.presenter_id = presenters.id OR channels.organization_id = organizations.id))
                           .where(%(user_accounts.available_by_request_for_live_vod IS TRUE))
                           .where(%(channels.status = ? AND channels.listed_at IS NOT NULL AND channels.archived_at IS NULL), Channel::Statuses::APPROVED)
                           .not_fake.for_home_page.limit(@limit).uniq
  end

  def evenly_split_common_users_if_any
    result_featured  = @raw_featured - @raw_on_demand
    result_on_demand = @raw_on_demand - @raw_featured

    a = (@raw_featured + @raw_on_demand)
    common = a.select { |e| a.count(e) > 1 }.uniq

    if common.present?
      left, right = common.each_slice((common.size / 2.0).round).to_a

      if left.present?
        result_featured += left
      end
      if right.present?
        result_on_demand += right
      end
    end

    @featured  = result_featured
    @on_demand = result_on_demand
  end

  # @return [User]
  def featured
    pre_fetch_featured_and_on_demand if @raw_featured.nil? || @raw_on_demand.nil?
    evenly_split_common_users_if_any if @featured.nil? || @on_demand.nil?

    @featured
  end

  # NOTE: "on demand presenter" is a presenter that has at least one not-archived, approved channel with  "I am also available by request for Live On-Demand Sessions" option
  # @return [User]
  def on_demand
    pre_fetch_featured_and_on_demand if @raw_featured.nil? || @raw_on_demand.nil?
    evenly_split_common_users_if_any if @featured.nil? || @on_demand.nil?

    @on_demand
  end

  # exclude presenters with default/missing avatars for now
  # @return [User]
  def brand_new
    @brand_new ||= begin
      exclude_user_ids = featured.collect(&:id) + on_demand.collect(&:id)
      exclude_user_ids = [-1] if exclude_user_ids.blank?
      User.joins(:image).joins(:presenter)
          .joins(%(LEFT JOIN organizations ON organizations.user_id = users.id))
          .joins(%(LEFT JOIN channels ON channels.organization_id = organizations.id OR channels.presenter_id = presenters.id))
          .where(%(channels.status = ? AND channels.listed_at IS NOT NULL AND channels.archived_at IS NULL), Channel::Statuses::APPROVED)
          .not_fake.for_home_page.where.not(id: exclude_user_ids).order(:created_at).limit(@limit).uniq
    end
  end
end
