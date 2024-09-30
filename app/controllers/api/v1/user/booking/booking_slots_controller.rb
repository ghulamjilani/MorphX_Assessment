# frozen_string_literal: true

module Api
  module V1
    module User
      module Booking
        class BookingSlotsController < Api::V1::User::Booking::ApplicationController
          before_action :set_booking_slot, only: %i[show update destroy]

          def index
            @booking_slots = if params[:user_id].present?
                               ::User.find(params[:user_id]).booking_slots.not_deleted
                             else
                               current_user.booking_slots.not_deleted
                             end
          end

          def new
            @booking_slot = current_user.booking_slots.new

            @channels = channels
          end

          def edit
            @booking_slot = current_user.booking_slots.find(params[:id])

            @channels = channels
          end

          def show
          end

          def create
            @booking_slot = current_user.booking_slots.new(booking_slot_params)

            if @booking_slot.save
              render :show, status: :created
            else
              render json: { message: @booking_slot.errors }, status: :unprocessable_entity
            end
          end

          def update
            if @booking_slot.update(booking_slot_params)
              render :show, status: :ok
            else
              render json: { message: @booking_slot.errors }, status: :unprocessable_entity
            end
          end

          def destroy
            @booking_slot.update!(deleted: true)
            @booking_slot.booking_prices.update_all(deleted: true)

            head :no_content
          end

          def calculate_price
            price = ::Booking::BookingSlot.not_deleted.find(params[:id]).calculate_price_by_duration(params[:price_id], DateTime.parse(params[:start_at]), DateTime.parse(params[:end_at]))
            render json: price, status: :ok
          rescue StandardError => e
            render json: { message: e.message }, status: :unprocessable_entity
          end

          def bookings
            booking_slot = ::Booking::BookingSlot.find(params[:id])
            if params[:date].present?
              date = DateTime.iso8601(params[:date])
              date_from = date.beginning_of_day
              date_to = date.end_of_day
            else
              date_from = DateTime.iso8601(params[:date_from]).beginning_of_day
              date_to = DateTime.iso8601(params[:date_to]).end_of_day
            end
            @bookings = booking_slot.bookings.where(%(bookings.start_at::timestamp BETWEEN :date_from AND :date_to OR bookings.end_at::timestamp BETWEEN :date_from AND :date_to), date_from: date_from, date_to: date_to)
          end

          private

          # Use callbacks to share common setup or constraints between actions.
          def set_booking_slot
            @booking_slot = current_user.booking_slots.not_deleted.find(params[:id])
          end

          # Only allow a list of trusted parameters through.
          def booking_slot_params
            params.require(:booking_slot).permit(:name, :description, :replay, :replay_price_cents, :currency,
                                                 :tags, :slot_rules, :week_rules, :booking_category_id, :channel_id,
                                                 booking_prices_attributes: %i[id duration price_cents currency deleted])
          end

          def channels
            raise(AccessForbiddenError) if current_user.current_organization.blank?

            @channels ||= begin
              if current_user == current_user.current_organization.user
                current_user.current_organization.channels
              else
                current_user.organization_channels_with_credentials(current_user.current_organization, :manage_booking)
              end.approved.not_archived.order(is_default: :desc, title: :asc)
            rescue StandardError
              []
            end

            raise(ActiveRecord::RecordNotFound, 'Channels not found') if @channels.blank?

            @channels
          end
        end
      end
    end
  end
end
