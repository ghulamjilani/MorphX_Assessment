# frozen_string_literal: true

envelope json do
  json.partial! 'site', site: @site
  json.activate_link @a_link
end
