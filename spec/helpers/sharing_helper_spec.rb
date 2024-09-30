# frozen_string_literal: true

require 'spec_helper'

describe SharingHelper do
  let(:helper) { Object.new.extend described_class }

  describe '#twitter_handle' do
    let(:twitter_handle) { helper.twitter_handle(model) }

    let(:model) { nil }
    let(:handle) { 'foobar' }

    it { expect { twitter_handle }.not_to raise_error }

    context 'when model is a user' do
      let(:social_link) { create(:social_link, link: link, provider: SocialLink::Providers::TWITTER) }

      let(:model) { social_link.entity.user }
      let(:link) { "@#{handle}" }

      it { expect { twitter_handle }.not_to raise_error }

      context 'when link start @' do
        let(:link) { "@#{handle}" }

        it { expect { twitter_handle }.not_to raise_error }
        it { expect(twitter_handle).to include(handle) }
      end

      context 'when link starts with http://twitter.com' do
        let(:link) { "http://twitter.com/#{handle}" }

        it { expect { twitter_handle }.not_to raise_error }
        it { expect(twitter_handle).to include(handle) }
      end

      context 'when link starts with https://twitter.com' do
        let(:link) { "https://twitter.com/#{handle}" }

        it { expect { twitter_handle }.not_to raise_error }
        it { expect(twitter_handle).to include(handle) }
      end

      context 'when link starts with twitter.com' do
        let(:link) { "twitter.com/#{handle}" }

        it { expect { twitter_handle }.not_to raise_error }
        it { expect(twitter_handle).to include(handle) }
      end

      context 'when link contains handle only' do
        let(:link) { handle }

        it { expect { twitter_handle }.not_to raise_error }
        it { expect(twitter_handle).to include(handle) }
      end
    end

    context 'when model is an organization' do
      let(:social_link) { create(:corpoprate_social_link, link: link, provider: SocialLink::Providers::TWITTER) }

      let(:model) { social_link.entity }
      let(:link) { "@#{handle}" }

      it { expect { twitter_handle }.not_to raise_error }

      context 'when link start @' do
        let(:link) { "@#{handle}" }

        it { expect { twitter_handle }.not_to raise_error }
        it { expect(twitter_handle).to include(handle) }
      end

      context 'when link starts with http://twitter.com' do
        let(:link) { "http://twitter.com/#{handle}" }

        it { expect { twitter_handle }.not_to raise_error }
        it { expect(twitter_handle).to include(handle) }
      end

      context 'when link starts with https://twitter.com' do
        let(:link) { "https://twitter.com/#{handle}" }

        it { expect { twitter_handle }.not_to raise_error }
        it { expect(twitter_handle).to include(handle) }
      end

      context 'when link starts with twitter.com' do
        let(:link) { "twitter.com/#{handle}" }

        it { expect { twitter_handle }.not_to raise_error }
        it { expect(twitter_handle).to include(handle) }
      end

      context 'when link contains handle only' do
        let(:link) { handle }

        it { expect { twitter_handle }.not_to raise_error }
        it { expect(twitter_handle).to include(handle) }
      end
    end

    context 'when model is a blog post' do
      let(:model) { build(:blog_post) }

      it { expect { twitter_handle }.not_to raise_error }
    end
  end
end
