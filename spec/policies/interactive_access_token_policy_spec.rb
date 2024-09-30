# frozen_string_literal: true

require 'spec_helper'

describe InteractiveAccessTokenPolicy do
  subject { described_class.new(user, interactive_access_token) }

  let(:interactive_access_token) { create(:interactive_access_token) }

  context 'when given a visitor' do
    let(:user) { nil }

    it { is_expected.not_to permit(:show)    }
    it { is_expected.not_to permit(:create)  }
    it { is_expected.not_to permit(:update)  }
    it { is_expected.not_to permit(:destroy) }
  end

  context 'when given a session presenter' do
    let(:user) { interactive_access_token.session.presenter.user }

    it { is_expected.to permit(:show)    }
    it { is_expected.to permit(:create)  }
    it { is_expected.to permit(:update)  }
    it { is_expected.to permit(:destroy) }
  end

  context 'when given a session channel organizer' do
    let(:user) { interactive_access_token.session.channel.organizer }

    it { is_expected.to permit(:show)    }
    it { is_expected.to permit(:create)  }
    it { is_expected.to permit(:update)  }
    it { is_expected.to permit(:destroy) }
  end

  context 'when given an invited presenter' do
    let(:presentership) { create(:channel_invited_presentership_accepted) }
    let(:user) { presentership.presenter.user }
    let(:session) { create(:published_session, channel: presentership.channel, presenter: presentership.presenter) }
    let(:interactive_access_token) { create(:interactive_access_token, session: session) }

    it { is_expected.to permit(:show)    }
    it { is_expected.to permit(:create)  }
    it { is_expected.to permit(:update)  }
    it { is_expected.to permit(:destroy) }
  end
end
