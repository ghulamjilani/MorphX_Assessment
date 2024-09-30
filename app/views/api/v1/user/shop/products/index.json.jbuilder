# frozen_string_literal: true

envelope json do
  json.array! @products do |product|
    json.partial! 'product', product: product
  end
end
