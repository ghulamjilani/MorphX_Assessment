# frozen_string_literal: true

ActiveAdmin.register_page 'RevenueOrganization' do
  menu parent: 'Analytics', label: 'Revenue Organization'

  sidebar :filters do
    organization_ids = (params[:oid].is_a?(Array) ? params[:oid].map(&:to_i) : nil) || Organization.not_fake.joins(:user).where(users: { fake: false }, id: Reports::V1::RevenueOrganization.most_popular_organizations.select(:id)).pluck(:id)
    collection = Organization.not_fake.joins(:user).where(users: { fake: false }).select(:name, :id).order(name: :asc).map do |o|
      [o.name, o.id, { checked: organization_ids.include?(o.id) }]
    end
    start_date = Date.parse((params[:start_date] || 3.month.ago).to_s)
    end_date = Date.parse((params[:end_date] || Date.today).to_s)

    active_admin_form_for Reports::V1::RevenueOrganization.new, url: service_admin_panel_revenueorganization_path,
                                                                method: :get, html: { class: 'filter_form' } do |f|
      f.inputs do
        f.input :detailed_channel_id, as: :hidden, input_html: { name: :detailed_channel_id, value: params[:detailed_channel_id] }
        f.input :start_date, as: :datepicker, label: 'Start Date', input_html: { name: :start_date, value: start_date }, datepicker_options: { max_date: Time.zone.now.to_date }
        f.input :end_date, as: :datepicker, label: 'End Date', input_html: { name: :end_date, value: end_date }, datepicker_options: { max_date: Time.zone.now.to_date }

        div(class: 'select_org') do
          link_to 'Check All', '#', onclick: '$(".filter_form input[type=\'checkbox\']").attr("checked", true);return false', class: 'button'
        end
        div(class: 'select_org') do
          link_to 'Uncheck All', '#', onclick: '$(".filter_form input[type=\'checkbox\']").attr("checked", false);return false', class: 'button'
        end

        f.input :organization_id, as: :check_boxes, collection: collection, checked: organization_ids,
                                  input_html: { name: '[oid][]' }, label: ''
      end
      f.submit 'Apply'
      div do
        link_to 'Reset Filters', service_admin_panel_revenueorganization_path, class: 'button'
      end
    end
  end

  page_action :update, method: :put do
    # TODO
  end

  content do
    panel 'Chart' do
      start_date = Date.parse((params[:start_date] || 3.month.ago).to_s)
      end_date = Date.parse((params[:end_date] || Date.today).to_s)
      organization_ids = (params[:oid].is_a?(Array) ? params[:oid].map(&:to_i) : nil) || Organization.not_fake.joins(:user).where(users: { fake: false }, id: Reports::V1::RevenueOrganization.most_popular_organizations.select(:id)).pluck(:id)
      channel_id = params[:detailed_channel_id].present? ? params[:detailed_channel_id].to_i : nil

      data = Organization.not_fake.joins(:user).where(users: { fake: false }, id: organization_ids).map do |o|
        if channel_id.present?
          { name: o.name, data: Reports::V1::RevenueOrganization.group_by_chart({
                                                                                  'channel_id': channel_id,
                                                                                  'date': { '$gte': start_date,
                                                                                            '$lte': end_date }
                                                                                }, 'total', 'day') }
        else
          { name: o.name, data: Reports::V1::RevenueOrganization.group_by_chart({
                                                                                  'organization_id': o.id,
                                                                                  'date': { '$gte': start_date,
                                                                                            '$lte': end_date }
                                                                                }, 'total', 'day') }
        end
      end

      line_chart data, download: true
    end
    panel 'Info' do
      start_date = Date.parse((params[:start_date] || 3.month.ago).to_s)
      end_date = Date.parse((params[:end_date] || Date.today).to_s)
      date_array = (start_date..end_date)
      organization_ids = (params[:oid].is_a?(Array) ? params[:oid].map(&:to_i) : nil) || Organization.not_fake.joins(:user).where(users: { fake: false }, id: Reports::V1::RevenueOrganization.most_popular_organizations.select(:id)).pluck(:id)

      table(border: '0', cellspacing: '0', cellpadding: '0', class: 'report') do
        thead do
          tr do
            th(class: 'col col-s dark', colspan: 3) do
              if params[:detailed_channel_id].present?
                link_to 'Back', url_for(:back)
              else
                ''
              end
            end
            th(class: 'col col-s', colspan: 4) { 'total' }
            th(class: 'col col-s dark', colspan: 5) { 'subscriptions' }
            th(class: 'col col-s', colspan: 5) { 'ppv_sessions' }
            th(class: 'col col-s dark', colspan: 5) { 'ppv_replays' }
            th(class: 'col col-s three', colspan: 5) { 'ppv_uploads' }
          end
          tr do
            th(class: 'col col-s dark') { 'organization' }
            th(class: 'col col-s dark') { 'channel' }
            if params[:detailed_channel_id].present?
              th(class: 'col col-s dark') { raw '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Date&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;' }
            else
              th(class: 'col col-s dark') { 'Detail' }
            end

            th(class: 'col col-s') { 'total' }
            th(class: 'col col-s') { 'income' }
            th(class: 'col col-s') { 'fee' }
            th(class: 'col col-s') { 'refund' }

            th(class: 'col col-s dark') { 'inc' }
            th(class: 'col col-s dark') { 'inc count' }
            th(class: 'col col-s dark') { 'fee' }
            th(class: 'col col-s dark') { 'ref' }
            th(class: 'col col-s dark') { 'ref count' }

            th(class: 'col col-s') { 'inc' }
            th(class: 'col col-s') { 'inc count' }
            th(class: 'col col-s') { 'fee' }
            th(class: 'col col-s') { 'ref' }
            th(class: 'col col-s') { 'ref count' }

            th(class: 'col col-s dark') { 'inc' }
            th(class: 'col col-s dark') { 'inc count' }
            th(class: 'col col-s dark') { 'fee' }
            th(class: 'col col-s dark') { 'ref' }
            th(class: 'col col-s dark') { 'ref count' }

            th(class: 'col col-s') { 'inc' }
            th(class: 'col col-s') { 'inc count' }
            th(class: 'col col-s') { 'fee' }
            th(class: 'col col-s') { 'ref' }
            th(class: 'col col-s') { 'ref count' }
          end
        end
        tbody do
          if params[:detailed_channel_id].present?
            Reports::V1::RevenueOrganization.where(channel_id: params[:detailed_channel_id],
                                                   date: date_array).order(date: :desc).each.with_index do |obj, index|
              tr(class: (index.odd? ? 'odd' : 'even').to_s) do
                td(class: 'col') { Organization.find_by(id: obj.organization_id)&.name if index.zero? }
                td(class: 'col') { Channel.find_by(id: obj.channel_id)&.title if index.zero? }
                td(class: 'col', style: 'width: 65px;') { obj.date }

                td(class: 'col') { obj.total / 100.0 }
                td(class: 'col') { obj.total_income / 100.0 }
                td(class: 'col') { obj.total_fee / 100.0 }
                td(class: 'col') { obj.total_refund / 100.0 }

                td(class: 'col') { obj.subscriptions_income / 100.0 }
                td(class: 'col') { obj.subscriptions_income_count }
                td(class: 'col') { obj.subscriptions_income_fee / 100.0 }
                td(class: 'col') { obj.subscriptions_refund / 100.0 }
                td(class: 'col') { obj.subscriptions_refund_count }

                td(class: 'col') { obj.ppv_sessions / 100.0 }
                td(class: 'col') { obj.ppv_sessions_count }
                td(class: 'col') { obj.ppv_sessions_fee / 100.0 }
                td(class: 'col') { obj.ppv_sessions_refund / 100.0 }
                td(class: 'col') { obj.ppv_sessions_refund_count }

                td(class: 'col') { obj.ppv_replays / 100.0 }
                td(class: 'col') { obj.ppv_replays_count }
                td(class: 'col') { obj.ppv_replays_income_fee / 100.0 }
                td(class: 'col') { obj.ppv_replays_refund / 100.0 }
                td(class: 'col') { obj.ppv_replays_refund_count }

                td(class: 'col') { obj.ppv_uploads / 100.0 }
                td(class: 'col') { obj.ppv_uploads_count }
                td(class: 'col') { obj.ppv_uploads_income_fee / 100.0 }
                td(class: 'col') { obj.ppv_uploads_refund / 100.0 }
                td(class: 'col') { obj.ppv_uploads_refund_count }
              end
            end
          else
            Organization.not_fake.joins(:user).where(users: { fake: false }, id: organization_ids).order(name: :asc).each do |org|
              org.channels.each.with_index do |channel, index|
                hash = Reports::V1::RevenueOrganization.where(organization_id: org.id, channel_id: channel.id, date: date_array).to_a
                tr(class: (index.odd? ? 'odd' : 'even').to_s) do
                  td(class: 'col') { org.name if index.zero? }
                  td(class: 'col') { channel.title }
                  td(class: 'col') do
                    link_to 'View', service_admin_panel_revenueorganization_path(params.permit!.slice(:start_date, :end_date).merge(detailed_channel_id: channel.id, oid: [org.id]))
                  end

                  td(class: 'col') { hash.sum { |i| i['total'] } / 100.0 }
                  td(class: 'col') { hash.map { |i| i['total_income'] }.compact.sum / 100.0 }
                  td(class: 'col') { hash.map { |i| i['total_fee'] }.compact.sum / 100.0 }
                  td(class: 'col') { hash.map { |i| i['total_refund'] }.compact.sum / 100.0 }

                  td(class: 'col') { hash.map { |i| i['subscriptions_income'] }.compact.sum / 100.0 }
                  td(class: 'col') { hash.map { |i| i['subscriptions_income_count'] }.compact.sum }
                  td(class: 'col') { hash.map { |i| i['subscriptions_income_fee'] }.compact.sum / 100.0 }
                  td(class: 'col') { hash.map { |i| i['subscriptions_refund'] }.compact.sum / 100.0 }
                  td(class: 'col') { hash.map { |i| i['subscriptions_refund_count'] }.compact.sum }

                  td(class: 'col') { hash.map { |i| i['ppv_sessions'] }.compact.sum / 100.0 }
                  td(class: 'col') { hash.map { |i| i['ppv_sessions_count'] }.compact.sum }
                  td(class: 'col') { hash.map { |i| i['ppv_sessions_fee'] }.compact.sum / 100.0 }
                  td(class: 'col') { hash.map { |i| i['ppv_sessions_refund'] }.compact.sum / 100.0 }
                  td(class: 'col') { hash.map { |i| i['ppv_sessions_refund_count'] }.compact.sum }

                  td(class: 'col') { hash.map { |i| i['ppv_replays'] }.compact.sum / 100.0 }
                  td(class: 'col') { hash.map { |i| i['ppv_replays_count'] }.compact.sum }
                  td(class: 'col') { hash.map { |i| i['ppv_replays_income_fee'] }.compact.sum / 100.0 }
                  td(class: 'col') { hash.map { |i| i['ppv_replays_refund'] }.compact.sum / 100.0 }
                  td(class: 'col') { hash.map { |i| i['ppv_replays_refund_count'] }.compact.sum }

                  td(class: 'col') { hash.map { |i| i['ppv_uploads'] }.compact.sum / 100.0 }
                  td(class: 'col') { hash.map { |i| i['ppv_uploads_count'] }.compact.sum }
                  td(class: 'col') { hash.map { |i| i['ppv_uploads_income_fee'] }.compact.sum / 100.0 }
                  td(class: 'col') { hash.map { |i| i['ppv_uploads_refund'] }.compact.sum / 100.0 }
                  td(class: 'col') { hash.map { |i| i['ppv_uploads_refund_count'] }.compact.sum }
                end
              end
            end
            ''
          end
        end
      end
    end
    div do
      link_to 'Download CSV', service_admin_panel_revenueorganization_csv_path(params.permit!.slice(:oid, :start_date, :end_date, :detailed_channel_id)), class: 'button'
    end
  end

  page_action :csv, method: :get do
    start_date = Date.parse((params[:start_date] || 3.month.ago).to_s)
    end_date = Date.parse((params[:end_date] || Date.today).to_s)
    date_array = (start_date..end_date)
    organization_ids = (params[:oid].is_a?(Array) ? params[:oid].map(&:to_i) : nil) || Organization.not_fake.joins(:user).where(users: { fake: false }, id: Reports::V1::RevenueOrganization.most_popular_organizations.select(:id)).pluck(:id)

    if params[:detailed_channel_id].present?
      csv = CSV.generate do |csv|
        csv << %w[organization channel date total total_income total_fee total_refund
                  subscriptions_income subscriptions_income_count subscriptions_income_fee subscriptions_refund subscriptions_refund_count
                  ppv_sessions ppv_sessions_count ppv_sessions_fee ppv_sessions_refund ppv_sessions_refund_count
                  ppv_replays ppv_replays_count ppv_replays_income_fee ppv_replays_refund ppv_replays_refund_count
                  ppv_uploads ppv_uploads_count ppv_uploads_income_fee ppv_uploads_refund ppv_uploads_refund_count]

        Organization.not_fake.joins(:user).where(users: { fake: false }, id: organization_ids).order(name: :asc).each do |org|
          [params[:detailed_channel_id]].each.with_index do |cid, _index|
            if (channel = Channel.find_by(id: cid))
              Reports::V1::RevenueOrganization.where(organization_id: org.id, channel_id: cid, date: date_array).each do |hash|
                csv << [
                  org.name, channel.title,
                  hash['date'], hash['total'] / 100.0, hash['total_income'].to_i / 100.0, hash['total_fee'].to_i / 100.0, hash['total_refund'].to_i / 100.0,
                  hash['subscriptions_income'].to_i / 100.0, hash['subscriptions_income_count'].to_i, hash['subscriptions_income_fee'].to_i / 100.0, hash['subscriptions_refund'].to_i / 100.0,
                  hash['subscriptions_refund_count'].to_i, hash['ppv_sessions'].to_i / 100.0, hash['ppv_sessions_count'].to_i, hash['ppv_sessions_fee'].to_i / 100.0, hash['ppv_sessions_refund'].to_i / 100.0,
                  hash['ppv_sessions_refund_count'].to_i, hash['ppv_replays'].to_i / 100.0, hash['ppv_replays_count'].to_i, hash['ppv_replays_income_fee'].to_i / 100.0, hash['ppv_replays_refund'].to_i / 100.0,
                  hash['ppv_replays_refund_count'].to_i, hash['ppv_uploads'].to_i / 100.0, hash['ppv_uploads_count'].to_i, hash['ppv_uploads_income_fee'].to_i / 100.0, hash['ppv_uploads_refund'].to_i / 100.0, hash['ppv_uploads_refund_count'].to_i
                ]
              end
            end
          end
        end
      end
    else
      csv = CSV.generate do |csv|
        csv << %w[organization channel total total_income total_fee total_refund
                  subscriptions_income subscriptions_income_count subscriptions_income_fee subscriptions_refund subscriptions_refund_count
                  ppv_sessions ppv_sessions_count ppv_sessions_fee ppv_sessions_refund ppv_sessions_refund_count
                  ppv_replays ppv_replays_count ppv_replays_income_fee ppv_replays_refund ppv_replays_refund_count
                  ppv_uploads ppv_uploads_count ppv_uploads_income_fee ppv_uploads_refund ppv_uploads_refund_count]

        Organization.not_fake.joins(:user).where(users: { fake: false }, id: organization_ids).order(name: :asc).each do |org|
          channel_ids = Reports::V1::RevenueOrganization.where(organization_id: org.id, date: date_array).order(total: :desc).pluck(:channel_id).uniq
          channel_ids.each.with_index do |cid, _index|
            if (channel = Channel.find_by(id: cid))
              hash = Reports::V1::RevenueOrganization.where(organization_id: org.id, channel_id: cid, date: date_array).to_a

              csv << [
                org.name, channel.title,
                hash.sum { |i| i['total'] } / 100.0,
                hash.map { |i| i['total_income'] }.compact.sum / 100.0,
                hash.map { |i| i['total_fee'] }.compact.sum / 100.0,
                hash.map { |i| i['total_refund'] }.compact.sum / 100.0,
                hash.map { |i| i['subscriptions_income'] }.compact.sum / 100.0,
                hash.map { |i| i['subscriptions_income_count'] }.compact.sum,
                hash.map { |i| i['subscriptions_income_fee'] }.compact.sum / 100.0,
                hash.map { |i| i['subscriptions_refund'] }.compact.sum / 100.0,
                hash.map { |i| i['subscriptions_refund_count'] }.compact.sum,
                hash.map { |i| i['ppv_sessions'] }.compact.sum / 100.0,
                hash.map { |i| i['ppv_sessions_count'] }.compact.sum,
                hash.map { |i| i['ppv_sessions_fee'] }.compact.sum / 100.0,
                hash.map { |i| i['ppv_sessions_refund'] }.compact.sum / 100.0,
                hash.map { |i| i['ppv_sessions_refund_count'] }.compact.sum,
                hash.map { |i| i['ppv_replays'] }.compact.sum / 100.0,
                hash.map { |i| i['ppv_replays_count'] }.compact.sum,
                hash.map { |i| i['ppv_replays_income_fee'] }.compact.sum / 100.0,
                hash.map { |i| i['ppv_replays_refund'] }.compact.sum / 100.0,
                hash.map { |i| i['ppv_replays_refund_count'] }.compact.sum,
                hash.map { |i| i['ppv_uploads'] }.compact.sum / 100.0,
                hash.map { |i| i['ppv_uploads_count'] }.compact.sum,
                hash.map { |i| i['ppv_uploads_income_fee'] }.compact.sum / 100.0,
                hash.map { |i| i['ppv_uploads_refund'] }.compact.sum / 100.0,
                hash.map { |i| i['ppv_uploads_refund_count'] }.compact.sum
              ]
            end
          end
        end
      end
    end

    send_data csv, type: 'text/csv; header=present',
                   disposition: "attachment; filename=transactions_#{DateTime.now}.csv"
  end
end
