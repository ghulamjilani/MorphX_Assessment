# frozen_string_literal: true

require 'spec_helper'

describe SpaPathsHelper do
  let(:helper) { Object.new.extend described_class }
  let(:organization) { create(:organization) }
  let(:blog_post) { create(:blog_post) }

  describe '#organization_absolute_url' do
    let(:subject1) { helper.organization_absolute_url(organization) }

    it { expect { subject1 }.not_to raise_error }
    it { expect(subject1).to be_truthy }
  end

  describe '#organization_community_absolute_url' do
    let(:subject2) { helper.organization_community_absolute_url(organization) }

    it { expect { subject2 }.not_to raise_error }
    it { expect(subject2).to be_truthy }
  end

  describe '#post_absolute_url' do
    let(:subject3) { helper.post_absolute_url(blog_post) }

    it { expect { subject3 }.not_to raise_error }
    it { expect(subject3).to be_truthy }
  end
end
