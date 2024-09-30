# frozen_string_literal: true

require 'spec_helper'

describe Auth::Jwt::Encoder do
  let(:user_token) { create(:auth_user_token) }
  let(:jwt) { JwtAuth.user_token(user_token) }
  let(:type) { Auth::Jwt::Types::USER_TOKEN }
  let(:model) { create(:auth_user_token) }

  factories = {
    Auth::Jwt::Types::USER_TOKEN => :auth_user_token,
    Auth::Jwt::Types::USER_TOKEN_REFRESH => :auth_user_token,
    Auth::Jwt::Types::GUEST => :guest,
    Auth::Jwt::Types::GUEST_REFRESH => :guest,
    Auth::Jwt::Types::ORGANIZATION => :organization,
    Auth::Jwt::Types::ORGANIZATION_INTEGRATION => :organization,
    Auth::Jwt::Types::USAGE => :user
  }

  types = Auth::Jwt::Types::ALL
  types.each do |type|
    context "when given type #{type}" do
      let(:model) { create(factories[type]).reload }

      describe '#encoder' do
        it { expect { described_class.new(type: type, model: model).encoder }.not_to raise_error }

        it { expect(described_class.new(type: type, model: model).encoder).to be_truthy }
      end

      describe '#encode' do
        it { expect { described_class.new(type: type, model: model).encode }.not_to raise_error }

        it { expect(described_class.new(type: type, model: model).encode).to be_truthy }
      end

      describe '#encode_refresh' do
        it { expect { described_class.new(type: type, model: model).encode_refresh }.not_to raise_error }

        unless [::Auth::Jwt::Types::USAGE, ::Auth::Jwt::Types::ORGANIZATION, ::Auth::Jwt::Types::ORGANIZATION_INTEGRATION].include?(type)
          it { expect(described_class.new(type: type, model: model).encode_refresh).to be_truthy }
        end
      end

      describe '#jwt' do
        it { expect { described_class.new(type: type, model: model).jwt }.not_to raise_error }

        it { expect(described_class.new(type: type, model: model).jwt).to be_truthy }
      end

      describe '#refresh_jwt' do
        it { expect { described_class.new(type: type, model: model).refresh_jwt }.not_to raise_error }

        unless [::Auth::Jwt::Types::USAGE, ::Auth::Jwt::Types::ORGANIZATION, ::Auth::Jwt::Types::ORGANIZATION_INTEGRATION].include?(type)
          it { expect(described_class.new(type: type, model: model).refresh_jwt).to be_truthy }
        end
      end

      describe '#expires_at' do
        it { expect { described_class.new(type: type, model: model).expires_at }.not_to raise_error }

        it { expect(described_class.new(type: type, model: model).expires_at).to be_truthy }
      end

      describe '#refresh_expires_at' do
        it { expect { described_class.new(type: type, model: model).refresh_expires_at }.not_to raise_error }

        it { expect(described_class.new(type: type, model: model).refresh_expires_at).to be_truthy }
      end
    end
  end
end
