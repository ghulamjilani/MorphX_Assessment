# frozen_string_literal: true

envelope json do
  json.products do
    json.array! @products do |product|
      json.product do
        json.partial! 'product', product: product
      end
    end
  end
  if @list
    json.list do
      json.partial! 'api/v1/public/shop/lists/list', list: @list
    end
  end
end
