# frozen_string_literal: true
class MindBodyDb::Location < MindBodyDb::ApplicationRecord
  belongs_to :site, class_name: 'MindBodyDb::Site', foreign_key: :mind_body_db_sites_id
end
