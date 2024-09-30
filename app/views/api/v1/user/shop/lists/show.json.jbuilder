# frozen_string_literal: true

envelope json, (@status || 200), (@list.pretty_errors if @list.errors.present?) do
  json.list do
    json.partial! 'list', list: @list
  end
  json.products do
    json.array! @list.products do |product|
      json.product do
        json.partial! 'api/v1/user/shop/products/product_short', product: product
      end
    end
  end
end
