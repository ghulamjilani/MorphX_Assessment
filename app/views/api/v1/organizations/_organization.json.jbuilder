# frozen_string_literal: true

json.id                   organization.id
json.user_id              organization.user_id
json.industry_id          organization.industry_id
json.name                 organization.name
json.website_url          organization.website_url
json.short_url            organization.short_url
json.referral_short_url   organization.referral_short_url
json.created_at           organization.created_at.utc.to_fs(:rfc3339)
json.created_at           organization.created_at.utc.to_fs(:rfc3339)
json.tagline              organization.tagline
json.description          organization.description
json.slug                 organization.slug
json.shares_count         organization.shares_count
json.show_on_home         organization.show_on_home
json.promo_start          organization.promo_start
json.promo_end            organization.promo_end
json.promo_weight         organization.promo_weight
