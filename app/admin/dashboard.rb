# frozen_string_literal: true

ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: proc { I18n.t('active_admin.dashboard') }

  content title: proc { I18n.t('active_admin.dashboard') } do
    columns do
      column do
        panel "List of sessions during a 24 hours. Current time in utc: #{Time.now.utc.to_s(:time)}" do
          rooms = Room.joins(session: { presenter: :user }).where('(actual_start_at::timestamp , actual_end_at::timestamp) overlaps (:start_at::timestamp ,:end_at::timestamp)',
                                                                  start_at: Time.now.utc, end_at: Time.now.utc + 24.hours)
                      .where(sessions: { fake: false }, users: { fake: false }).order('actual_start_at asc')
          table_for rooms do
            column('User') do |room|
              link_to(User.find_by(id: room.presenter_user_id).try(:email), service_admin_panel_user_path(room.presenter_user_id))
            end
            column('Session ') do |room|
              if room.abstract_session_type == 'Session'
                link_to("#{room.abstract_session_type}: #{room.abstract_session.try(:title).to_s.truncate(34)}",
                        service_admin_panel_session_path(room.abstract_session_id))
              end
            end
            column('Starts in') do |room|
              lambda do
                unless room.abstract_session.started?
                  return distance_of_time_in_words(room.abstract_session.start_at, Time.now.utc, include_seconds: true)
                end

                status_tag 'red', label: 'live' if room.active?
              end.call
            end
            column('Prep Time') { |room| "#{room.abstract_session.pre_time}m" }
            column('Start at') { |room| utc_and_admin_time_formatted(room.abstract_session.start_at, MORPHX_SHORT_TIME_FORMAT) }
            column('End at') { |room| utc_and_admin_time_formatted(room.actual_end_at, MORPHX_SHORT_TIME_FORMAT) }
            column('Status') do |room|
              if room.abstract_session.finished?
                'Finished'
              elsif room.actual_start_at < Time.now
                link_to('Stop', stop_session_service_admin_panel_room_path(room.id), data: { confirm: 'Are you sure?' })
              else
                'Not started'
              end
            end
            if authorized?(:manage, Room)
              column('Control') do |room|
                link_to 'Control', room_control_service_admin_panel_room_path(room)
              end
            end
          end
        end

        panel 'New Users' do
          users = User.not_fake.order('created_at DESC').limit(10)
          table_for(users) do
            column('Created at') { |user| strong user.created_at.to_s(:short).to_s }
            column('Email') do |user|
              link_to(user.email.to_s.truncate(54), service_admin_panel_user_path(user.id))
            end
            column('Email confirm') do |user|
              if user.confirmed?
                status_tag 'ok', label: 'confirmed'
              else
                status_tag('Un-confirmed')
              end
            end
          end
        end

        sessions = Session.upcoming.not_cancelled.not_stopped.not_fake.joins(presenter: :user)
                          .where(status: Session::Statuses::REQUESTED_FREE_SESSION_PENDING, users: { fake: false })
                          .limit(10).order(start_at: :desc)
        if sessions.present?
          panel "Pending Requested Free Sessions(#{sessions.size})" do
            table_for(sessions) do
              column('User') do |session|
                link_to(session.presenter&.user&.email, service_admin_panel_user_path(session.presenter.user_id))
              end
              column('Session') do |session|
                link_to session.always_present_title, service_admin_panel_session_path(session.id)
              end
              column('Prep Time') do |session|
                "#{session.pre_time}m"
              end
              column('Start At (UTC)') do |session|
                session.start_at.utc.to_s(:short)
              end
            end
          end
        end

        # presenters who didn't finish *becoming a presenter*(didn't create channel at 3rd step)
        panel 'Incomplete Presenters' do
          presenters = Presenter.joins(:user).where(users: { fake: false })
                                .where.not(last_seen_become_presenter_step: [nil, :wizard_complete])
                                .order('users.created_at DESC').limit(20).preload(:user) # means "at least saw info/step1/step2 page"
          table_for presenters do
            column('Created at') { |presenter| strong presenter.user.created_at.to_s(:short).to_s }
            column('Email') do |presenter|
              link_to(presenter.user.email.to_s.truncate(54), service_admin_panel_user_path(presenter.user.id))
            end
            column('Current step') { |presenter| strong I18n.t("activeadmin.dashboard.wizard_steps.#{presenter.last_seen_become_presenter_step}") if presenter.last_seen_become_presenter_step }
          end
        end

        if Channel.not_fake.pending_review.present?
          panel 'Pending Channels' do
            ul do
              Channel.joins(organization: :user).pending_review.where(users: { fake: false }).last(10).each do |channel|
                li do
                  strong raw("[#{channel.created_at.to_s(:short)}] #{link_to channel.title,
                                                                             service_admin_panel_channel_path(channel.id)}")
                  div ActionView::Base.full_sanitizer.sanitize(channel.description.to_s).truncate(100).to_s
                end
              end
            end
          end
        end

        panel 'Top 5 popular Presenter' do
          table_for User.joins(:presenter, :follows)
                        .select(%{users.*, COUNT(follows.*) AS count_user_followers})
                        .where(%(follows.follower_id = users.id AND follows.follower_type = 'User' AND users.fake IS FALSE))
                        .group(%(users.id)).order(count_user_followers: :desc).limit(5) do
            column('Id') { |user| strong user.id }
            column('Email') { |user| link_to(user.email, service_admin_panel_user_path(user.id)) }
            column('Name') { |user| strong user.public_display_name }
            column('Followers') { |user| strong user.count_user_followers }
          end
        end

        if current_admin.morphx_admin? || current_admin.superadmin?
          panel 'Reindex' do
            para do
              %w[All User Channel Session Video Recording Blog::Post].map do |name|
                link_to("[#{(name == 'All') ? name : name.pluralize}]",
                        service_admin_panel_dashboard_reindex_path(entities: name))
              end.join(' | ').html_safe
            end
          end
        end

        if current_admin.morphx_admin? || current_admin.superadmin?
          panel 'System actions' do
            para do
              link_to('Update comments count', service_admin_panel_dashboard_update_comments_count_path)
            end

            para do
              link_to('Clear cache', service_admin_panel_dashboard_clear_cache_path)
            end
          end
        end
      end

      if current_admin.morphx_admin? || current_admin.superadmin?
        column do
          para do
            strong { 'Last deploy' }
            span do
              DateTime.parse((`pwd`.to_s.scan(/\d+/).first)).to_s(:short)
            rescue StandardError
              'Cant parse'
            end
          end

          panel 'System Parameters' do
            table_for SystemParameter.all do
              column('Parameter') do |system_parameter|
                title = system_parameter.key.tr('_', ' ')
                if system_parameter.description.present?
                  %(<strong alt="#{system_parameter.description}" title="#{system_parameter.description}" style="text-decoration: underline; cursor: help">#{title}</strong>).html_safe
                else
                  strong title
                end
              end

              column('Value') do |system_parameter|
                if system_parameter.key.include?('cost') || system_parameter.key.include?('fee')
                  number_to_currency(system_parameter.value, precision: 2)
                else
                  system_parameter.value
                end
              end
            end
          end

          table do
            columns do
              column do
                panel 'Stats' do
                  para do
                    strong { 'Users count' }
                    span { User.count }
                  end
                  para do
                    strong { 'Un-confirmed users count' }
                    span { User.where(confirmed_at: nil).count }
                  end
                  para do
                    strong { 'Real presenters count' }
                    # TODO: Presenters logic changed
                    span { Presenter.has_channels.count }
                  end
                  para do
                    strong { 'Participants count' }
                    span { Participant.count }
                  end
                end
              end
              column do
                panel 'Ffmpegservice accounts pool' do
                  pool_size = Rails.application.credentials.backend.dig(:initialize, :ffmpegservice_account, :pool_size) || 100
                  transcoder_types = %i[passthrough transcoded]
                  %i[rtmp rtsp webrtc].each do |protocol|
                    transcoder_types.each do |transcoder_type|
                      para do
                        strong { "#{protocol} #{transcoder_type.eql?(:passthrough) ? 'free' : 'paid'} " }
                        span do
                          "#{FfmpegserviceAccount.not_assigned.where(protocol: protocol,
                                                             transcoder_type: transcoder_type).count}/#{pool_size}"
                        end
                        span do
                          " (#{FfmpegserviceAccount.not_assigned.not_sandbox.where(protocol: protocol,
                                                                           transcoder_type: transcoder_type).count} live)"
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end # content
  end

  page_action :reindex, method: [:get] do
    ReindexJob.perform_async(params[:entities])
    redirect_to service_admin_panel_dashboard_path, notice: 'Reindex job will be completed soon.'
  end

  page_action :update_comments_count, method: [:get] do
    BlogJobs::UpdateCommentsCountJob.perform_async
    redirect_to service_admin_panel_dashboard_path, notice: 'Comment counters will be updated soon.'
  end

  page_action :clear_cache, method: [:get] do
    Rails.cache.clear
    redirect_to service_admin_panel_dashboard_path, notice: 'Cache cleared.'
  end
end
