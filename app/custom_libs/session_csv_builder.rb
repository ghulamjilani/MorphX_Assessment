# frozen_string_literal: true

class SessionCsvBuilder < ::ActiveAdmin::CSVBuilder
  def build(view_context, receiver)
    options = ActiveAdmin.application.csv_options.merge self.options
    column_names = [
      'Session ID',
      'Session Date',
      'Session Name',
      'Creator',
      'Participant',
      'Session Type',
      'Transaction ID',
      'Transaction Date',
      'Session Price',
      'Service Fee',
      'Creator Revenue',
      'Immerss Revenue'
    ]
    receiver << CSV.generate_line(column_names, options)

    total_creator_revenue = 0
    total_immerss_revenue = 0
    total_service_fee = 0
    view_context.send(:collection).find_each do |resource|
      creator_percent = resource.organizer.revenue_percent / 100.0
      immerss_percent = (100 - resource.organizer.revenue_percent) / 100.0
      fee = resource.immersive_service_fee
      if resource.immersive_delivery_method? && resource.immersive_purchase_price.positive?
        creator_revenue = (resource.immersive_purchase_price.to_f - fee) * creator_percent
        immerss_revenue = (resource.immersive_purchase_price.to_f - fee) * immerss_percent
        resource.paid_immersive_session_participations.find_each do |p|
          total_service_fee += fee
          total_creator_revenue += creator_revenue
          total_immerss_revenue += immerss_revenue
          user = p.participant.user
          bttr = resource.payment_transactions.where(user_id: user.id).first
          row = [
            resource.id,
            resource.start_at,
            resource.title,
            resource.organizer.display_name,
            user.display_name,
            'Immersive',
            bttr.pid,
            bttr.checked_at,
            resource.immersive_purchase_price,
            fee,
            creator_revenue.round(2),
            immerss_revenue.round(2)
          ]
          receiver << CSV.generate_line(row, options)
        end
      end
      if resource.livestream_delivery_method? && resource.livestream_purchase_price.positive?
        creator_revenue = (resource.livestream_purchase_price.to_f - fee) * creator_percent
        immerss_revenue = (resource.livestream_purchase_price.to_f - fee) * immerss_percent
        resource.paid_livestreamers.find_each do |p|
          total_service_fee += fee
          total_creator_revenue += creator_revenue
          total_immerss_revenue += immerss_revenue
          user = p.participant.user
          bttr = resource.payment_transactions.where(user_id: user.id).first
          row = [
            resource.id,
            resource.start_at,
            resource.title,
            resource.organizer.display_name,
            user.display_name,
            'Livestream',
            bttr.pid,
            bttr.checked_at,
            resource.livestream_purchase_price,
            fee,
            creator_revenue.round(2),
            immerss_revenue.round(2)
          ]
          receiver << CSV.generate_line(row, options)
        end
      end
    end
    arr = [
      nil, nil, nil, nil, nil, nil, nil, nil,
      'Total:',
      total_service_fee.round(2),
      total_creator_revenue.round(2),
      total_immerss_revenue.round(2)
    ]
    receiver << CSV.generate_line(arr, options)
  end
end
