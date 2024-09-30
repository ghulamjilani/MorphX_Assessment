# frozen_string_literal: true
class MindBodyDb::ClassRoom < MindBodyDb::ApplicationRecord
  belongs_to :class_schedule, class_name: 'MindBodyDb::ClassSchedule', foreign_key: :mind_body_db_class_schedule_id
  belongs_to :site, class_name: 'MindBodyDb::Site', foreign_key: :mind_body_db_site_id
end
