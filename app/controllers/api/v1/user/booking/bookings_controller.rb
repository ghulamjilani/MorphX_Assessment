# frozen_string_literal: true

module Api
  module V1
    module User
      module Booking
        class BookingsController < Api::V1::User::Booking::ApplicationController
          before_action :set_booking, only: %i[show destroy]

          def index
            @bookings = if params[:requested_bookings]
                          current_user.requested_bookings
                        else
                          current_user.bookings
                        end

            @bookings = if params[:date].present?
                          date = DateTime.iso8601(params[:date])
                          date_from = date.beginning_of_day
                          date_to = date.end_of_day
                          @bookings.where(%(bookings.start_at::timestamp BETWEEN :date_from AND :date_to OR bookings.end_at::timestamp BETWEEN :date_from AND :date_to), date_from: date_from, date_to: date_to)
                        elsif params[:date_from].present? && params[:date_to].present?
                          date_from = DateTime.iso8601(params[:date_from]).beginning_of_day
                          date_to = DateTime.iso8601(params[:date_to]).end_of_day
                          @bookings.where(%(bookings.start_at::timestamp BETWEEN :date_from AND :date_to OR bookings.end_at::timestamp BETWEEN :date_from AND :date_to), date_from: date_from, date_to: date_to)
                        else
                          @bookings
                        end
          end

          def show
          end

          def create
            booking_slot = ::Booking::BookingSlot.find(params[:booking][:booking_slot_id])
            @booking = current_user.bookings.new(booking_params)
            unless @booking.valid?
              return render json: { message: @booking.errors }, status: :unprocessable_entity
            end

            token = params[:booking][:stripe_token]
            stripe_card = params[:booking][:stripe_card]
            # Create or update stripe customer
            begin
              if current_user.has_payment_info?
                # check if this is not existing card token
                customer = current_user.stripe_customer
                source = if token
                           Stripe::Customer.create_source(customer.id, { source: token })
                         elsif stripe_card
                           current_user.find_stripe_customer_source(stripe_card)
                         end

                if source
                  customer.default_source = source
                  customer.save
                end
              else
                customer = Stripe::Customer.create(
                  email: current_user.email,
                  description: current_user.public_display_name,
                  source: token
                )
                current_user.stripe_customer_id = customer.id
                current_user.save(validate: false)
              end
            rescue StandardError => e
              return render json: { message: e.message }, status: :unprocessable_entity
            end
            begin
              charge_amount = booking_slot.calculate_price_by_duration(params[:booking][:price_id], DateTime.parse(params[:booking][:start_at]), DateTime.parse(params[:booking][:end_at]))
              invoice_params = {
                customer: customer.id,
                # default_tax_rates: [@tax], # Skip For now because we don't have tax
                description: "Booking for Slot##{booking_slot.id} - #{booking_slot.name}"
              }
              invoice_params[:default_source] = source if source
              invoice = Stripe::Invoice.create(invoice_params)
              invoice_item_params = {
                customer: customer.id,
                amount: charge_amount,
                currency: 'usd',
                description: "Booking for Slot##{booking_slot.id} - #{booking_slot.name}",
                invoice: invoice.id
              }
              Stripe::InvoiceItem.create(invoice_item_params)

              invoice.pay
              invoice = Stripe::Invoice.retrieve(invoice.id)
              charge = Stripe::Charge.retrieve(invoice.charge)
            rescue StandardError => e
              return render json: { message: e.message }, status: :unprocessable_entity
            end

            if invoice.paid
              @booking.status = :approved
              @booking.customer_paid = true
              unless @booking.save
                return render json: { message: @booking.errors }, status: :unprocessable_entity
              end

              stripe_transaction = PaymentTransaction.find_or_initialize_by(provider: :stripe, pid: charge.id)
              stripe_transaction.amount = invoice.amount_paid
              stripe_transaction.amount_currency = invoice.currency
              stripe_transaction.type = TransactionTypes::BOOKING
              stripe_transaction.user = current_user
              stripe_transaction.purchased_item = @booking.booking_price
              stripe_transaction.credit_card_last_4 = charge.source.last4
              stripe_transaction.card_type = charge.source.brand
              stripe_transaction.status = charge.status
              stripe_transaction.country = charge.source.country
              stripe_transaction.zip = charge.source.address_zip
              stripe_transaction.name_on_card = charge.source.name
              stripe_transaction.tax_cents = 0 # (invoice.amount_paid / 100.0 * @tax).round
              stripe_transaction.checked_at = Time.zone.at(charge.created)
              stripe_transaction.save

              @booking.update(payment_transaction_id: stripe_transaction.id)

              current_user.log_transactions.create!(type: LogTransaction::Types::BOOKING,
                                                    abstract_session: booking_slot,
                                                    image_url: stripe_transaction.image_url,
                                                    amount: -stripe_transaction.total_amount / 100.0,
                                                    payment_transaction: stripe_transaction)
            else
              return render json: { message: 'Payment failed' }, status: :unprocessable_entity
            end
            render :show, status: :created
          end

          # def update
          #   if @booking.update(booking_params)
          #     render :show, status: :ok
          #   else
          #     render json: @booking.errors, status: :unprocessable_entity
          #   end
          # end

          def destroy
            @booking.destroy

            head :no_content
          end

          private

          # Use callbacks to share common setup or constraints between actions.
          def set_booking
            @booking = current_user.bookings.find(params[:id])
          end

          # Only allow a list of trusted parameters through.
          def booking_params
            params.require(:booking).permit(:booking_slot_id, :duration, :start_at, :end_at, :comment).tap do |attrs|
              attrs[:booking_price_id] = params[:booking][:price_id]
            end
          end
        end
      end
    end
  end
end
