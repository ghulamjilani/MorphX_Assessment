# frozen_string_literal: true
class MindBodyDb::Site < MindBodyDb::ApplicationRecord
  has_many :locations, class_name: 'MindBodyDb::Location', foreign_key: :mind_body_db_sites_id, dependent: :destroy
  has_many :staffs, class_name: 'MindBodyDb::Staff', foreign_key: :mind_body_db_site_id, dependent: :destroy
  has_many :class_descriptions, class_name: 'MindBodyDb::ClassDescription', foreign_key: :mind_body_db_site_id,
                                dependent: :destroy
  has_many :class_schedules, class_name: 'MindBodyDb::ClassSchedule', foreign_key: :mind_body_db_site_id,
                             dependent: :destroy
  has_many :class_rooms, class_name: 'MindBodyDb::ClassRoom', foreign_key: :mind_body_db_site_id, dependent: :destroy

  belongs_to :organization

  module PricingLevels
    NO_SUBSCRIPTION   = 'No Subscription'
    ACCELERATE        = 'Accelerate'
    ESSENTIAL         = 'Essential'
    LEGACY            = 'Legacy'
    CONNECT_LISTING   = 'Connect Listing'
    PRO               = 'Pro'
    SOLO              = 'Solo'
    ESSENTIAL_2_0     = 'Essential 2.0'
    ACCELERATE_2_0    = 'Accelerate 2.0'
    ULTIMATE_2_0      = 'Ultimate 2.0'
    STARTER           = 'Starter'

    ALL = [
      NO_SUBSCRIPTION,
      ACCELERATE,
      ESSENTIAL,
      LEGACY,
      CONNECT_LISTING,
      PRO,
      SOLO,
      ESSENTIAL_2_0,
      ACCELERATE_2_0,
      ULTIMATE_2_0,
      STARTER
    ].freeze
  end

  validates :organization_id, presence: true
  validates :pricing_level, inclusion: { in: PricingLevels::ALL }
  validates :remote_id, presence: true

  after_commit :load_site_data, on: :create

  private

  def load_site_data
    MindBodyJobs::Location::LoadSiteLocations.perform_async(id)
    MindBodyJobs::Staff::LoadSiteStaffs.perform_async(id)
    MindBodyJobs::ClassRoom::LoadSiteClassRooms.perform_async(id)
    MindBodyJobs::ClassSchedule::LoadSiteClassSchedules.perform_async(id)
    MindBodyJobs::ClassDescription::LoadSiteClassDescriptions.perform_async(id)
  end
end
