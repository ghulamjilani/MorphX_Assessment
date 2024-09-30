# frozen_string_literal: true

class Api::V1::Public::MindBody::ClassSchedulesController < Api::V1::ApplicationController
  skip_before_action :authorization

  def index
    query = MindBodyDb::ClassSchedule.preload(:staff, :class_description, :location, :class_rooms)
                                     .joins(:location).where(mind_body_db_locations: { mind_body_db_sites_id: site_id })

    if params[:start_date_after] && params[:start_date_before]
      query = query.where(start_date: params[:start_date_after]..params[:start_date_before])
    elsif params[:start_date_after]
      query = query.where('start_date >= ?', params[:start_date_after])
    elsif params[:start_date_before]
      query = query.where('start_date <= ?', params[:start_date_before])
    end

    if params[:end_date_after] && params[:end_date_before]
      query = query.where(end_date: params[:end_date_after]..params[:end_date_before])
    elsif params[:end_date_after]
      query = query.where('end_date >= ?', params[:end_date_after])
    elsif params[:end_date_before]
      query = query.where('end_date <= ?', params[:end_date_before])
    end

    query = query.order(start_time: :desc)

    @count = query.count
    @class_schedules = query.limit(@limit).offset(@offset)
  end

  private

  def site_id
    @site_id ||= MindBodyDb::Site.find_by(organization_id: params['organization_id'])&.id
  end
end
