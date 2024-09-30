# frozen_string_literal: true

class MindBodyJobs::Location::LoadSiteLocations < ApplicationJob
  sidekiq_options queue: 'low'

  # class schedule has been created or updated
  def perform(mind_body_db_site_id, params = { Limit: 200 })
    site = MindBodyDb::Site.find(mind_body_db_site_id)
    client = MindBodyLib::Api::Location.new(credentials: { site_id: site.remote_id })

    response = client.locations(params)
    response[:Locations].each do |data|
      data = MindBodyLib::Map.location(data)

      raise 'remote_id missing' if data.compact.blank? || data[:remote_id].blank?

      MindBodyDb::Location.find_or_create_by!(mind_body_db_sites_id: mind_body_db_site_id,
                                              remote_id: data[:remote_id]).update!(data.compact)
    rescue StandardError => e
      Airbrake.notify("MindBodyOnline LoadSiteLocations #{e.message}", parameters: {
                        mind_body_db_site_id: mind_body_db_site_id,
                        params: params,
                        data: data
                      })
    end

    processed_count = response.dig(:PaginationResponse,
                                   :RequestedOffset).to_i + response.dig(:PaginationResponse, :PageSize).to_i
    if processed_count < response.dig(:PaginationResponse, :TotalResults)
      params[:Offset] = processed_count
      MindBodyJobs::Location::LoadSiteLocations.perform_async(mind_body_db_site_id, params)
    end
  rescue StandardError => e
    Airbrake.notify("MindBodyJobs::Location::LoadSiteLocations #{e.message}", parameters: {
                      mind_body_db_site_id: mind_body_db_site_id,
                      params: params
                    })
  end
end
