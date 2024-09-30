# frozen_string_literal: true

class Api::V1::User::DocumentsController < Api::V1::User::ApplicationController
  before_action :set_document, only: %i[show update destroy buy]

  # GET api/v1/user/documents
  def index
    @documents = Document.not_archived.includes_file.joins(:channel)
                         .where(channels: { archived_at: nil })

    if params[:dashboard].present?
      channels = current_user.all_channels_with_credentials(:manage_documents)
      @documents = @documents.where(channel_id: channels.pluck(:id))
      @documents = @documents.where(hidden: params[:hidden]) unless params[:hidden].nil?
    else
      @documents = @documents.visible.where(channels: { show_documents: true })
    end
    @documents = @documents.where(channel_id: params[:channel_id]) if params[:channel_id]
    @count = @documents.count
    @documents = @documents.order(created_at: :desc)
                           .limit(@limit)
                           .offset(@offset)
  end

  # GET api/v1/user/documents/:id
  def show
    authorize! :show, @document
  end

  # POST api/v1/user/documents
  def create
    # TODO: improve MI-6 - what about uploaded and not attached blobs?
    @document = Document.new(document_create_params)
    authorize! :create, @document
    @document.save!
    render :show
  end

  # PUT api/v1/user/documents/:id
  # Allows update title and description of the file
  def update
    authorize! :update, @document
    @document.update!(document_update_params)
    render :show
  end

  # DELETE api/v1/user/documents/:document_id
  # Destroys Document and relations
  def destroy
    authorize! :destroy, @document
    @document.destroy!
    render :show
  end

  def buy
    return render_json(403, 'You already bought this document') unless can?(:purchase, @document)

    @charge_amount = (@document.purchase_price * 100).to_i
    begin
      if current_user.has_payment_info?
        # check if this is not existing card token
        @customer = current_user.stripe_customer
        @source = if params[:stripe_token]
                    Stripe::Customer.create_source(@customer.id, { source: params[:stripe_token] })
                  elsif params[:stripe_card]
                    current_user.find_stripe_customer_source(params[:stripe_card])
                  end

        if @source
          @customer.default_source = @source
          @customer.save
        end
      else
        @customer = Stripe::Customer.create(
          email: current_user.email,
          description: current_user.public_display_name,
          source: params[:stripe_token] || params[:stripe_card]
        )
        current_user.stripe_customer_id = @customer.id
        current_user.save(validate: false)
      end
    rescue StandardError => e
      return render_json(422, e.message)
    end

    @country = params[:country] || @source&.address_country
    @zip_code = params[:zip_code] || @source&.address_zip
    @tax = 0

    begin
      invoice_params = {
        customer: @customer.id,
        # default_tax_rates: [@tax], # Skip For now because we don't have tax
        description: "Obtain document##{@document.id}.#{@discount ? " Coupon: #{@discount.name}" : ''}"
      }
      invoice_params[:default_source] = @source if @source
      invoice = Stripe::Invoice.create(invoice_params)
      invoice_item_params = {
        customer: @customer.id,
        amount: @charge_amount,
        currency: 'usd',
        description: "Obtain document##{@document.id}.#{@discount ? " Coupon: #{@discount.name}" : ''}",
        invoice: invoice.id
      }
      Stripe::InvoiceItem.create(invoice_item_params)

      invoice.pay
      invoice = Stripe::Invoice.retrieve(invoice.id)
      charge = Stripe::Charge.retrieve(invoice.charge)
    rescue StandardError => e
      return render_json(422, e.message)
    end
    if invoice.paid
      @stripe_transaction = PaymentTransaction.find_or_initialize_by(provider: :stripe, pid: charge.id)
      @stripe_transaction.amount = invoice.amount_paid
      @stripe_transaction.amount_currency = invoice.currency
      @stripe_transaction.type = TransactionTypes::DOCUMENT
      @stripe_transaction.user = current_user
      @stripe_transaction.purchased_item = @document
      @stripe_transaction.credit_card_last_4 = charge.source.last4
      @stripe_transaction.card_type = charge.source.brand
      @stripe_transaction.status = charge.status
      @stripe_transaction.country = charge.source.country
      @stripe_transaction.zip = charge.source.address_zip
      @stripe_transaction.name_on_card = charge.source.name
      @stripe_transaction.tax_cents = (invoice.amount_paid / 100.0 * @tax).round
      @stripe_transaction.checked_at = Time.zone.at(charge.created)
      @stripe_transaction.save!

      @current_user.log_transactions.create!(type: LogTransaction::Types::DOCUMENT,
                                             abstract_session: @document,
                                             amount: -@stripe_transaction.amount / 100.0,
                                             payment_transaction: @stripe_transaction)
      @document.user.log_transactions.create!(type: LogTransaction::Types::NET_INCOME,
                                              abstract_session: @document,
                                              amount: @stripe_transaction.amount * (@document.user.revenue_percent / 100.0) / 100.0,
                                              payment_transaction: @stripe_transaction)

      @document.document_members.create(user: current_user, payment_transaction: @stripe_transaction)
      render :show
    else
      render_json(422, invoice.status)
    end
  end

  private

  def set_document
    @document = Document.find(params[:id])
  end

  def document_create_params
    params.require(:document).permit(:channel_id, :file, :title, :description, :hidden, :purchase_price, :only_ppv, :only_subscription)
  end

  def document_update_params
    params.require(:document).permit(:title, :description, :hidden, :purchase_price, :only_ppv, :only_subscription)
  end

  def current_ability
    @current_ability ||= AbilityLib::DocumentAbility.new(current_user)
  end
end
