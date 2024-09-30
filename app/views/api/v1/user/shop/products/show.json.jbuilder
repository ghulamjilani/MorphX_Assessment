# frozen_string_literal: true

envelope json, (@status || 200), (@product.pretty_errors if @product.errors.present?) do
  json.product do
    json.partial! 'product_short', product: @product
  end

  if @list
    json.list do
      json.partial! 'api/v1/user/shop/lists/list', list: @list
    end
  end
end
