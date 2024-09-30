# frozen_string_literal: true

envelope json do
  json.ad_banners do
    json.array! @ad_banner_keys do |key|
      json.set! key do
        json.array! ::PageBuilder::AdBanner.active.where(key: key).order(name: :asc)
      end
    end
  end
end
