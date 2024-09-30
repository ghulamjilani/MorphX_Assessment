# frozen_string_literal: true

require 'spec_helper'

describe LoginHelper do
  let(:helper) { Object.new.extend described_class }

  describe '#omniauth_provider_active?(provider)' do
    %i[facebook gplus twitter instagram linkedin apple zoom].each do |provider|
      subject(:helper_method) { helper.omniauth_provider_active?(provider) }

      it { expect { helper_method }.not_to raise_error }
    end
  end
end
