# frozen_string_literal: true
require 'spec_helper'

describe SocialLink do
  describe '#link_as_url' do
    let(:hashes) do
      [
        { link: 'www.theothersideofthetracks.com', provider: 'explicit' },
        { link: 'http://www.fredcoince.com', provider: 'explicit' },
        { link: 'www.elainegoodfood.com', provider: 'explicit' },
        { link: 'https://unite.live', provider: 'explicit' },
        { link: 'Http://www.kandisdoesyoga.com', provider: 'explicit' },
        { link: 'http://www.realitycrowdtv.com', provider: 'explicit' },
        { link: 'www.lynchburgsalsa.com', provider: 'explicit' },

        { link: '@CJLYoga', provider: 'facebook' },
        { link: '@CJLYoga ', provider: 'facebook' },
        { link: '@davidrl.roberts', provider: 'facebook' },
        { link: 'https://www.facebook.com/CJLYoga', provider: 'facebook' },
        { link: 'https://www.facebook.com/davidrl.roberts?fref=ts', provider: 'facebook' },
        { link: 'https://www:facebook.com/good2eat4U', provider: 'facebook' },
        { link: 'https://www.facebook.com/fred.coince', provider: 'facebook' },
        { link: 'https://facebook.com/immerss', provider: 'facebook' },
        { link: 'https://www.facebook.com/AndreaReynoldsFIT', provider: 'facebook' },
        { link: 'http://www.facebook.com/mannymoments', provider: 'facebook' },
        { link: 'www.facebook.com/lynchburgsalsa1', provider: 'facebook' },
        { link: 'facebook.com/lynchburgsalsa1', provider: 'facebook' },

        { link: '/themosthappyyou ', provider: 'twitter' },
        { link: '/themosthappyyou', provider: 'twitter' },
        { link: '@davidrlroberts', provider: 'twitter' },
        { link: '@good2eat4U', provider: 'twitter' },
        { link: 'https://twitter.com/ImmerssMe', provider: 'twitter' },
        { link: 'http://www.twitter.com/averagejoevc', provider: 'twitter' },
        { link: 'www.twitter.com/lynchburgsalsa', provider: 'twitter' },
        { link: 'twitter.com/lynchburgsalsa', provider: 'twitter' },

        { link: 'https://www.linkedin.com/pub/david-roberts/23/431/9a2', provider: 'linkedin' },
        { link: 'https://fr.linkedin.com/pub/fred-coince/46/36a/308', provider: 'linkedin' },
        { link: 'http://www.linkedin.com/in/msfinarolakis', provider: 'linkedin' },
        { link: 'linkedin.com/in/msfinarolakis', provider: 'linkedin' },

        { link: 'good2eat4u', provider: 'instagram' },
        { link: '@good2eat4u', provider: 'instagram' },
        { link: ' good2eat4u ', provider: 'instagram' },
        { link: 'https://www.Instagram.com/good2eat4u', provider: 'instagram' },
        { link: 'https://Instagram.com/good2eat4u', provider: 'instagram' },
        { link: 'http://www.Instagram.com/good2eat4u', provider: 'instagram' },
        { link: 'http://Instagram.com/good2eat4u', provider: 'instagram' },
        { link: 'www.Instagram.com/good2eat4u', provider: 'instagram' },
        { link: 'Instagram.com/good2eat4u', provider: 'instagram' },
        { link: 'instagram.com/good2eat4u', provider: 'instagram' },
        { link: 'http://www.instagram.com/realitycrowdtv', provider: 'instagram' },
        { link: 'www.instagram.com/lynchburgsalsa', provider: 'instagram' },

        { link: 'https://plus.google.com/+ManolisSfinarolakiscrowdfunding/posts', provider: 'google+' },
        { link: 'fred coince', provider: 'google+' },

        { link: 'https://www.youtube.com/user/elainebgood', provider: 'youtube' },
        { link: 'https://www.youtube.com/playlist?list=PLOaIzJF8DdQblD5lKcOjCHbwICo0pbZv4', provider: 'youtube' }
      ]
    end

    it 'does not fail' do
      expect { hashes.each { |attrs| described_class.new(attrs).link_as_url } }.not_to raise_error
    end
  end
end
