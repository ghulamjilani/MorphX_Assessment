# frozen_string_literal: true

UTM.configure do |conf|
  # == Campaign Source (utm_source)
  # Required. Use utm_source to identify a search engine, newsletter
  # name, or other source.
  # * Example: utm_source=google
  conf.utm_source   = 'email-notification'

  # == Campaign Medium (utm_medium)
  # Required. Use utm_medium to identify a medium such as email or
  # cost-per- click.
  # * Example: utm_medium=cpc
  conf.utm_medium   = 'email'

  # Campaign Name (utm_campaign)
  # Used for keyword analysis. Use utm_campaign to identify a specific
  # product promotion or strategic campaign.
  # * Example: utm_campaign=spring_sale
  conf.utm_campaign = 'notifications'
end
