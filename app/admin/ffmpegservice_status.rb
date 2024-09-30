# frozen_string_literal: true

ActiveAdmin.register_page 'Ffmpegservice Status' do
  menu parent: 'Ffmpegservice'

  page_action :stop_stream, method: :get do
    stream_id = params[:stream_id]
    Sender::Ffmpegservice.new(sandbox: false).stop_stream(stream_id) if stream_id
    redirect_back fallback_location: service_admin_panel_ffmpegservice_status_path, notice: "Stopping livestream #{stream_id}"
  end

  page_action :reset_stream, method: :get do
    stream_id = params[:stream_id]
    Sender::Ffmpegservice.new(sandbox: false).reset_stream(stream_id) if stream_id
    redirect_back fallback_location: service_admin_panel_ffmpegservice_status_path, notice: "Resetting livestream #{stream_id}"
  end

  page_action :start_stream, method: :get do
    stream_id = params[:stream_id]
    Sender::Ffmpegservice.new(sandbox: false).start_stream(stream_id) if stream_id
    redirect_back fallback_location: service_admin_panel_ffmpegservice_status_path, notice: "Starting livestream #{stream_id}"
  end

  content do
    client = Sender::Ffmpegservice.new(sandbox: false)

    panel 'Active transcoders' do
      transcoders = client.transcoders({ filter: { '0': { field: 'state',
                                                          in: 'starting,resetting,stopping,started' } } })[:transcoders]
      collection = []
      transcoders.each do |transcoder|
        transcoder = client.get_transcoder(transcoder[:id])
        transcoder_state = client.state_transcoder(transcoder[:id])
        transcoder_stats = client.stats_transcoder(transcoder[:id])
        ffmpegservice_account = FfmpegserviceAccount.find_by(stream_id: transcoder[:id])
        collection << {
          transcoder: transcoder,
          transcoder_state: transcoder_state,
          transcoder_stats: transcoder_stats,
          ffmpegservice_account: ffmpegservice_account
        }
      end

      render partial: 'transcoders_table', locals: { collection: collection }
    end

    panel 'Active ffmpegservice sessions' do
      table_for Session.ongoing.not_stopped.where.not(ffmpegservice_account_id: nil) do
        column :id
        column :presenter
        column :ffmpegservice_account do |session|
          link_to(session.ffmpegservice_account_id, service_admin_panel_ffmpegservice_account_path(session.ffmpegservice_account_id),
                  target: '_blank')
        end
        column :stream_id do |session|
          session.ffmpegservice_account.stream_id
        end
        column :room_status do |session|
          session.room.status
        end
        column :start_at
        column :end_at
      end
    end

    panel 'Get ffmpegservice info' do
      if (@stream_id = params[:stream_id]).present?
        @ffmpegservice_account = FfmpegserviceAccount.find_by(stream_id: @stream_id)
        @ffmpegservice_account_id = @ffmpegservice_account&.id
      elsif (@ffmpegservice_account_id = params[:ffmpegservice_account_id])
        @ffmpegservice_account = FfmpegserviceAccount.find_by(id: @ffmpegservice_account_id)
        @stream_id = @ffmpegservice_account&.stream_id
      end

      if @ffmpegservice_account
        @active_sessions = Session.ongoing.where(ffmpegservice_account_id: @ffmpegservice_account.id)
      end

      if @stream_id.present?
        @transcoder = client.get_transcoder(@stream_id)
        @livestream = client.livestream(@stream_id)
        @transcoder_state = client.state_transcoder
        @livestream_state = client.state_stream
        @transcoder_stats = client.stats_transcoder
        @livestream_stats = client.stats_stream
        collection = [{
          transcoder: @transcoder,
          transcoder_state: @transcoder_state,
          transcoder_stats: @transcoder_stats,
          ffmpegservice_account: @ffmpegservice_account
        }]
      end

      render partial: 'search_transcoder_form', locals: { ffmpegservice_account_id: @ffmpegservice_account_id, stream_id: @stream_id }

      if @transcoder.present?
        panel 'Short Info' do
          render partial: 'transcoders_table', locals: { collection: collection }
        end
      end

      if @transcoder.present?
        panel 'Detailed Info' do
          textarea_style = 'width: 100%; height: 400px; font-size: 1.2em;'
          tabs do
            tab :transcoder do
              textarea(disabled: true, style: textarea_style) do
                JSON.pretty_generate(JSON.parse(@transcoder.to_json))
              end
            end
            tab :transcoder_state do
              textarea(disabled: true, style: textarea_style) do
                JSON.pretty_generate(JSON.parse(@transcoder_state.to_json))
              end
            end
            tab :transcoder_stats do
              textarea(disabled: true, style: textarea_style) do
                JSON.pretty_generate(JSON.parse(@transcoder_stats.to_json))
              end
            end
            tab :livestream do
              textarea(disabled: true, style: textarea_style) do
                JSON.pretty_generate(JSON.parse(@livestream.to_json))
              end
            end
            tab :livestream_state do
              textarea(disabled: true, style: textarea_style) do
                JSON.pretty_generate(JSON.parse(@livestream_state.to_json))
              end
            end
            tab :livestream_stats do
              textarea(disabled: true, style: textarea_style) do
                JSON.pretty_generate(JSON.parse(@livestream_stats.to_json))
              end
            end
            if @ffmpegservice_account
              tab :ffmpegservice_account do
                textarea(disabled: true, style: textarea_style) do
                  JSON.pretty_generate(JSON.parse(@ffmpegservice_account.attributes.to_json))
                end
              end
            end
            if @active_sessions.present?
              tab :active_sessions do
                @active_sessions.map do |s|
                  link_to("#{s.id}: #{s.title}", service_admin_panel_session_path(s.id))
                end.join("\n").html_safe
              end
            end
          end
        end
      end
    end
  end

  controller do
    def access_denied(exception)
      redirect_to service_admin_panel_dashboard_path, alert: exception.message
    end
  end
end
