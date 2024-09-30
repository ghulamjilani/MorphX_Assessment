# frozen_string_literal: true

namespace :webhook do
  namespace :v1 do
    resources :mind_body_online, only: [] do
      collection do
        match :create, via: %i[post head]
      end
    end
    resources :qencode, only: [] do
      collection do
        match :video, via: %i[post get]
        match :recording, via: %i[post get]
      end
    end
    resources :transfer_server, param: :ident, only: [] do
      member do
        post :create
      end
    end
    resources :zoom, only: [] do
      collection do
        match :create, via: %i[post head]
        match :deauthorize, via: %i[post head]
      end
    end
    resources :ffmpegservice, only: [] do
      collection do
        match :create, via: %i[post get]
      end
    end
    resources :webrtcservice, only: [:create]
  end
end
