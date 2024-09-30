# frozen_string_literal: true
class MindBodyDb::ClassDescription < MindBodyDb::ApplicationRecord
  has_many :class_schedules, class_name: 'MindBodyDb::ClassSchedule', foreign_key: :mind_body_db_class_description_id,
                             dependent: :destroy
  belongs_to :site, class_name: 'MindBodyDb::Site', foreign_key: :mind_body_db_site_id
end
