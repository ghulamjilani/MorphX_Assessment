# frozen_string_literal: true

require 'spec_helper'

describe Auth::Jwt::Decoder do
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
    context "when given jwt for #{type}" do
      let(:model) { create(factories[type]).reload }
      let(:jwt) do
        if type.include?('refresh')
          Auth::Jwt::Encoder.new(type: type, model: model).refresh_jwt
        else
          Auth::Jwt::Encoder.new(type: type, model: model).jwt
        end
      end

      describe '#decoder' do
        it { expect { described_class.new(jwt).decoder }.not_to raise_error }

        it { expect(described_class.new(jwt).decoder).to be_truthy }
      end

      describe '#type' do
        it { expect { described_class.new(jwt).type }.not_to raise_error }

        it { expect(described_class.new(jwt).type).to be_truthy }
      end

      describe '#payload' do
        it { expect { described_class.new(jwt).payload }.not_to raise_error }

        it { expect(described_class.new(jwt).payload).to be_truthy }
      end

      describe '#jwt' do
        it { expect { described_class.new(jwt).jwt }.not_to raise_error }

        it { expect(described_class.new(jwt).jwt).to be_truthy }
      end

      describe '#decode' do
        it { expect { described_class.new(jwt).decode }.not_to raise_error }

        it { expect(described_class.new(jwt).decode).to be_truthy }
      end

      describe '#decode!' do
        it { expect { described_class.new(jwt).decode! }.not_to raise_error }

        it { expect(described_class.new(jwt).decode!).to be_truthy }
      end

      describe '#model' do
        it { expect { described_class.new(jwt).model }.not_to raise_error }

        it { expect(described_class.new(jwt).model).to be_truthy }
      end

      describe '#valid?' do
        it { expect { described_class.new(jwt).valid? }.not_to raise_error }

        it { expect(described_class.new(jwt)).to be_valid }
      end

      describe '#validate' do
        it { expect { described_class.new(jwt).validate }.not_to raise_error }

        it { expect(described_class.new(jwt).validate).to be_truthy }
      end

      describe '#validate!' do
        it { expect { described_class.new(jwt).validate! }.not_to raise_error }

        it { expect(described_class.new(jwt).validate!).to be_truthy }
      end

      describe '#errors' do
        it { expect { described_class.new(jwt).errors }.not_to raise_error }

        it { expect(described_class.new(jwt).errors).to be_truthy }
      end

      describe '#expires_at' do
        it { expect { described_class.new(jwt).expires_at }.not_to raise_error }

        it { expect(described_class.new(jwt).expires_at).to be_truthy }
      end

      describe '#expired?' do
        it { expect { described_class.new(jwt).expired? }.not_to raise_error }

        it { expect(described_class.new(jwt)).not_to be_expired }
      end
    end
  end
end
