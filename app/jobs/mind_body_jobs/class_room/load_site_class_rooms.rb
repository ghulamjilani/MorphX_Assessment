# frozen_string_literal: true

class MindBodyJobs::ClassRoom::LoadSiteClassRooms < ApplicationJob
  sidekiq_options queue: 'low'

  # class room has been created or updated
  def perform(mind_body_db_site_id, params = { Limit: 200 })
    site = MindBodyDb::Site.find(mind_body_db_site_id)
    client = MindBodyLib::Api::ClassRoom.new(credentials: { site_id: site.remote_id })

    response = client.class_rooms(params)
    response[:Classes].each do |data|
      data = MindBodyLib::Map.class_room(data)

      raise 'remote_id missing' if data.compact.blank? || data[:remote_id].blank?

      MindBodyDb::ClassRoom.find_or_create_by!(mind_body_db_site_id: mind_body_db_site_id,
                                               remote_id: data[:remote_id]).update!(data.compact)
    rescue StandardError => e
      Airbrake.notify("MindBodyOnline LoadSiteClassRooms #{e.message}", parameters: {
                        mind_body_db_site_id: mind_body_db_site_id,
                        params: params,
                        data: data
                      })
    end

    processed_count = response.dig(:PaginationResponse,
                                   :RequestedOffset).to_i + response.dig(:PaginationResponse, :PageSize).to_i
    if processed_count < response.dig(:PaginationResponse, :TotalResults)
      params[:Offset] = processed_count
      MindBodyJobs::ClassRoom::LoadSiteClassRooms.perform_async(mind_body_db_site_id, params)
    end
  rescue StandardError => e
    Airbrake.notify("MindBodyJobs::ClassRoom::LoadSiteClassRooms #{e.message}", parameters: {
                      mind_body_db_site_id: mind_body_db_site_id,
                      params: params
                    })
  end
end
