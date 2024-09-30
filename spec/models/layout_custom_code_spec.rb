# frozen_string_literal: true
require 'spec_helper'

describe LayoutCustomCode do
  let(:layout_custom_code) { create(:layout_custom_code) }

  describe '#sanitize_content' do
    it { expect { layout_custom_code.sanitize_content }.not_to raise_error }
  end

  describe '#enable!' do
    it { expect { layout_custom_code.enable! }.not_to raise_error }
  end

  describe '#disable!' do
    it { expect { layout_custom_code.disable! }.not_to raise_error }
  end
end
