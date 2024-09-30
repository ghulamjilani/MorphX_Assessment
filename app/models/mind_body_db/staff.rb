# frozen_string_literal: true
class MindBodyDb::Staff < MindBodyDb::ApplicationRecord
  has_many :class_schedules, class_name: 'MindBodyDb::ClassSchedule', foreign_key: :mind_body_db_staff_id,
                             dependent: :destroy

  belongs_to :site, class_name: 'MindBodyDb::Site', foreign_key: :mind_body_db_site_id
  belongs_to :user, class_name: 'User', foreign_key: :user_id

  after_commit :assign_user, on: %i[create update], unless: ->(staff) { staff.user_id.present? }

  private

  def assign_user
    MindBodyJobs::Staff::AssignUser.perform_async(id)
  end
end
