# frozen_string_literal: true

envelope json do
  json.embed do
    %w[video video_additions video_shop video_shop_additions].each do |partial_name|
      (0..4).flat_map { |size| %w[live chat external_playlist single_item].combination(size).to_a }.each do |query|
        next if query.include?('chat')              && partial_name.exclude?('additions')
        next if query.include?('external_playlist') && partial_name.exclude?('additions')
        next if query.include?('single_item')       && partial_name.include?('additions')

        json.set! ([partial_name] + query).join('_'), CGI.unescapeHTML(render partial: "api/v1/shared/embeds/#{partial_name}", formats: [:html], locals: { share_model: @shared_model, query: query.inject({}) do |res, o|
                                                                                                                                                                                                res[o] = 'true';
                                                                                                                                                                                                res
                                                                                                                                                                                              end }).gsub(/\R+/, '')
      end
    end
  end
end
