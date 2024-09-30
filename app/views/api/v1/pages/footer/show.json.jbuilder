# frozen_string_literal: true

envelope json, (@status || 200) do
  json.footer do
    json.logo_url(
      if customize_logo_url.present?
        image_url(customize_logo_url)
      else
        image_url('footerLogo.png', class: 'footerLogo', alt: 'footer Logo')
      end
    )
    json.copyright "© #{Time.now.year} Unite."
  end
end
