# frozen_string_literal: true
class MindBodyDb::ClassSchedule < MindBodyDb::ApplicationRecord
  belongs_to :class_description, class_name: 'MindBodyDb::ClassDescription',
                                 foreign_key: :mind_body_db_class_description_id
  belongs_to :staff, class_name: 'MindBodyDb::Staff', foreign_key: :mind_body_db_staff_id
  belongs_to :location, class_name: 'MindBodyDb::Location', foreign_key: :mind_body_db_location_id
  belongs_to :site, class_name: 'MindBodyDb::Site', foreign_key: :mind_body_db_site_id

  has_many   :class_rooms, class_name: 'MindBodyDb::ClassRoom', foreign_key: :mind_body_db_class_schedule_id,
                           dependent: :destroy
  has_many   :sessions, inverse_of: :mind_body_db_class_schedule, foreign_key: :mind_body_db_class_schedule_id
end
