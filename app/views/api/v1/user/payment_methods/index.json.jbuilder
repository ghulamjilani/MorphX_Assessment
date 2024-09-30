# frozen_string_literal: true

envelope json do
  json.cards do
    json.array! @cards do |card|
      json.partial! 'card', card: card
    end
  end
  json.default_card @default_card
end
