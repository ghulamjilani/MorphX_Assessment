# frozen_string_literal: true

require 'spec_helper'

describe SystemJobs::ServerTimeJob do
  it { expect { described_class.new.perform }.not_to raise_error }
end
