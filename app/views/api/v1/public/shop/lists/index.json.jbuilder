# frozen_string_literal: true

envelope json do
  json.lists do
    json.array! @lists do |list|
      json.list do
        json.partial! 'list', list: list
      end
      json.products do
        json.array! list.products do |product|
          json.product do
            json.partial! 'api/v1/public/shop/products/product_short', product: product
          end
        end
      end
    end
  end
end
