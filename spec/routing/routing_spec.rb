# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/DescribeClass
describe 'routing to', type: 'routing' do
  # rubocop:enable RSpec/DescribeClass
  context 'when /johnb' do
    it 'works' do
      expect({ get: '/johnb' }).to route_to controller: 'not_found_or_title_parameterized',
                                            action: 'user_or_channel_or_session_or_organization',
                                            raw_slug: 'johnb'
    end
  end

  context 'when switch_user middleware requests' do
    it 'work' do
      expect({ get: '/switch_user?scope_identifier=user_25' }).to route_to action: 'set_current_user',
                                                                           controller: 'switch_user',
                                                                           scope_identifier: 'user_25'
    end
  end

  context 'when GET /users/password' do
    it 'works' do
      expect({ get: '/users/password/new' }).to route_to action: 'new', controller: 'users/passwords'
    end
  end

  context 'when PUT /users/password' do
    it 'works' do
      expect({ put: '/users/password' }).to route_to action: 'update', controller: 'users/passwords'
    end
  end
end
