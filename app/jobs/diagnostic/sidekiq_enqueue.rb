# frozen_string_literal: true

class Diagnostic::SidekiqEnqueue < ApplicationJob
  sidekiq_options queue: :critical

  def perform(*_args)
    check_auto_start_session
    check_stop_session
    check_start_ffmpegservice_stream
    check_missing_jobs
  end

  private

  # => {"class"=>"ApiJobs::AutoStartSession", "args"=>[13278], "retry"=>3, "queue"=>"default", "backtrace"=>20, "jid"=>"0e82cb648649f2ae2d7c0e7f", "created_at"=>1590112884.4856913}
  def check_auto_start_session
    extract(ApiJobs::AutoStartSession) do |obj|
      session = Room.find(obj['args'].first).abstract_session
      session.start_at.utc.to_fs(:rfc3339) == Time.at(obj['at']).utc.to_fs(:rfc3339)
    end
  end

  # => {"class"=>"ApiJobs::StopSession", "args"=>[13278], "retry"=>3, "queue"=>"default", "backtrace"=>20, "jid"=>"b6a1f176a9865c980d942333", "created_at"=>1590112884.5514414, "at"=>2020-08-18 11:49:55 UTC}
  def check_stop_session
    extract(ApiJobs::StopSession) do |obj|
      room = Room.find(obj['args'].first)
      (room.actual_end_at - 5.seconds).utc.to_fs(:rfc3339) == Time.at(obj['at']).utc.to_fs(:rfc3339)
    end
  end

  def check_start_ffmpegservice_stream
    extract(ApiJobs::StartFfmpegserviceStream) do |obj|
      room_id, skip = (obj['args'].count > 1) ? obj['args'] : [obj['args'][0], false]
      skip || (Room.find(room_id).actual_start_at + 5.seconds).utc.to_fs(:rfc3339) == Time.at(obj['at']).utc.to_fs(:rfc3339)
    end
  end

  def extract(klass)
    @scheduled ||= Sidekiq::ScheduledSet.new.map { |ss| JSON.parse(ss.value).merge!('at' => ss.at) }
    @scheduled.select { |o| o['class'] == klass.to_s }.each do |obj|
      raise("Wrong time for job #{klass}") unless yield obj
    rescue StandardError => e
      if e.message == 'Wrong time for job ApiJobs::StopSession'
        fix_api_jobs_stop_session(obj)
      else
        Airbrake.notify(e, { obj: obj })
      end
    end
  end

  # This error raise because presenter can close session on api part, and sidekiq know nothing about it
  # It should be removed when API migration in to Portal
  def fix_api_jobs_stop_session(obj)
    room = Room.find(obj['args'].first)
    if room.closed?
      SidekiqSystem::Schedule.remove(ApiJobs::StopSession, room.id)
    else
      Airbrake.notify('Room is not closed', { obj: obj })
    end
  end

  def check_missing_jobs
    @scheduled = Sidekiq::ScheduledSet.new
    upcoming_rooms = Room.where('now() < actual_start_at').where(status: %i[active awaiting]) # .not_closed.not_cancelled
    upcoming_rooms.find_each do |room|
      if room.awaiting?
        if room.ffmpegservice?
          start_stream_job = @scheduled.find do |job|
            job.klass == 'ApiJobs::StartFfmpegserviceStream' && job.args[0] == room.id
          end
          if start_stream_job.blank?
            Airbrake.notify('ApiJobs::StartFfmpegserviceStream is not scheduled for upcoming room',
                            { room_id: room.id })
          end
        end

        if !room.zoom? && room.autostart
          autostart_job = @scheduled.find { |job| job.klass == 'ApiJobs::AutoStartSession' && job.args[0] == room.id }
          if autostart_job.blank?
            Airbrake.notify('ApiJobs::AutoStartSession is not scheduled for upcoming room',
                            { room_id: room.id })
          end
        end
      end

      stop_session_job = @scheduled.find { |job| job.klass == 'ApiJobs::StopSession' && job.args[0] == room.id }
      if stop_session_job.blank?
        Airbrake.notify('ApiJobs::StopSession is not scheduled for upcoming room',
                        { room_id: room.id })
      end
    end
  end
end
