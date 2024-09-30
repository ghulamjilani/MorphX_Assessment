# frozen_string_literal: true

module Api
  module V1
    module User
      module Shop
        class ProductsController < Api::V1::User::ApplicationController
          before_action :check_credentials, except: %i[index show]
          before_action :load_list, only: %i[create]
          before_action :load_product, only: %i[show update destroy]

          def index
            query = current_user.current_organization.products
            @count = query.count
            order_by = %w[created_at updated_at title].include?(params[:order_by]) ? params[:order_by] : 'created_at'
            order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
            @lists = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
          end

          def show
          end

          def create
            @product = current_user.current_organization.products.find_or_initialize_by(url: params[:product][:url])

            @product.attributes = product_attributes

            if @product.save
              @product.update(image_attributes) if image_attributes
              @product.lists << @list if @list
              render :show
            end
          end

          def update
            if @product.update(product_attributes) && (image_attributes[:product_image_attributes] && image_attributes[:product_image_attributes][:original] && image_attributes)
              @product.update(image_attributes)
            end
            render :show
          end

          def destroy
            @product.destroy
            head 200
          end

          def search_by_upc
            barcode = params.require(:barcode)
            @product = current_user.current_organization.products.where('barcodes ILIKE ?', "%#{barcode}%").first

            if @product.blank?
              unless (lookup_result = Sales::ProductInfo.new(current_user).lookup(barcode: barcode))
                return render_json(404, 'No product found')
              end

              params[:product] = ActionController::Parameters.new lookup_result
              @product = current_user.current_organization.products.find_or_initialize_by(url: scanned_attributes[:url])
              if @product.new_record?
                @product.attributes = scanned_attributes
                @product.save
              end
            end

            if @product.errors.present?
              @status = 422

              return render :show
            end

            @list = current_user.current_organization.lists.find_by(id: params[:list_id]) if params[:list_id].present?
            @list ||= current_user.current_organization.lists.find_or_create_by(name: 'Scans')

            @list.products << @product unless @list.products.exists?(id: @product.id)

            @session = params[:session_id].present? ? Session.live_now.find_by(id: params[:session_id]) : Session.live_now.where(presenter_id: current_user.presenter_id).first

            @session.room.product_scanned(@product, @list) if @session&.room

            render :show
          end

          private

          def scanned_attributes
            params.require(:product).permit(:partner, :barcodes, :title, :description, :url, :short_description,
                                            :specifications, :price_cents, :price_currency, :raw_info,
                                            product_image_attributes: [:remote_original_url],
                                            stores_attributes: %i[min_price_cents max_price_cents price_currency
                                                                  category manufacturer advertiser url])
          end

          def load_product
            @product = current_user.current_organization.products.find(params[:id])
          end

          def load_list
            @list = current_user.current_organization.lists.find_by(id: params[:list_id])
          end

          def check_credentials
            authorize!(:manage_product, current_user.current_organization)
          end

          def product_attributes
            params.require(:product).permit(:title, :description, :url, :short_description, :specifications, :price).tap do |p|
              if p[:price]
                Monetize.assume_from_symbol = true
                p[:price] = Monetize.parse(p[:price])
                if p[:url] && (@product.new_record? || @product.url != p[:url] || @product.affiliate_url.blank?)
                  parser = Sales::ProductUrl.new(p[:url], current_user)
                  parser.extract
                  p[:partner] = parser.partner
                  p[:base_url] = parser.direct_url.to_s
                  p[:affiliate_url] = parser.affiliate_url.to_s
                end
              end
            end
          end

          def image_attributes
            params.require(:product).permit(product_image_attributes: %i[remote_original_url original])
          end
        end
      end
    end
  end
end
