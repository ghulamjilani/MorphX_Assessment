# frozen_string_literal: true

require 'spec_helper'

describe SearchController do
  describe 'GET :show' do
    render_views

    let(:search_query) { 'Some Random Searchquery' }
    let(:user) { create(:user, display_name: "#{search_query} Sedan") }
    let(:presenter) { create(:presenter, user: user) }
    let(:organization) { create(:organization, user: user) }
    let!(:presentership) do
      create(:channel_invited_presentership, presenter: presenter, channel: create(:listed_channel))
    end
    let(:channel_match_in_title) { create(:listed_channel, title: "Test Channel #{search_query} Baklazhan") }
    let(:channel_match_in_presenter) { create(:listed_channel, presenter: presenter) }
    let(:channel_match_in_presentership) { presentership.channel.reload }
    let(:channel_match_in_organization_user) { create(:listed_channel, organization: organization).reload }
    let(:channel_with_no_match) { create(:listed_channel, title: 'Ugly Fat Guy\'s Channel') }

    # it 'does not fail' do
    #   get :show, format: :html, params: { q: search_query }
    #   expect(response).to be_successful
    # end

    # it 'finds channel with full match in the title' do
    #   channel_match_in_title
    #   get :show, format: :html, params: { q: search_query}
    #   expect(response.body).to include(channel_match_in_title.title)
    # end

    # it 'finds channel with full match in the name of channel presenter' do
    #   channel_match_in_presenter
    #   get :show, format: :html, params: { q: search_query}
    #   expect(response.body).to include(channel_match_in_presenter.title)
    # end

    # it 'finds channel with full match in the name of invited presenter' do
    #   channel_match_in_presentership.multisearch_reindex
    #   get :show, format: :html, params: { q: search_query}
    #   expect(response.body).to include(channel_match_in_presentership.title)
    # end

    # it 'finds channel with match in the name of channel organization user' do
    #   channel_match_in_organization_user
    #   get :show, format: :html, params: { q: search_query}
    #   expect(response.body).to include(channel_match_in_organization_user.title)
    # end

    # it "does not display channels that don\'t match" do
    #   channel_with_no_match
    #   get :show, format: :html, params: { q: search_query}
    #   expect(response.body).not_to include(channel_with_no_match.title)
    # end
  end
end
