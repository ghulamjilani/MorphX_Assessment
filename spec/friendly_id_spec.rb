# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/DescribeClass
describe 'friendly_id slugs' do
  # rubocop:enable RSpec/DescribeClass
  let(:x) { create(:user, display_name: 'Foo Bar') }
  let(:y) { create(:channel, title: 'Foo Bar') }

  it {    expect(x.slug).not_to eq(y.slug) }
  it {    expect(x.slug).to eq('foo-bar') }
  it {    expect(y.slug).to eq("#{y.organization.slug}/#{y.title.parameterize}") }

  it 'assigns globally unique slugs' do
    x.display_name = 'noo way'
    x.save
    expect(x.reload.slug).to eq('noo-way')
  end

  it 'works for sessions too' do
    y = create(:approved_channel, title: 'Foo Bar')
    x = create(:immersive_session, title: 'Baz Qux', channel: y)
    expect(x.slug).to eq(x.normalize_friendly_id(nil))
  end
end
