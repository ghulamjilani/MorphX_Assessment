# frozen_string_literal: true
require 'spec_helper'

describe UserAccount do
  describe 'validations' do
    context 'image' do
      it 'checks dimensions' do
        pending 'TODO: move this test to profiles#update_user_image method verification(higher level)'
        path = Rails.root.join('spec/support/1x1.png').to_s
        user = create(:user)
        i = user.build_image
        i.image_50_x_50   = File.open(path)
        i.image_253_x_260 = File.open(path)
        i.image_277_x_280 = File.open(path)

        expect(i).not_to be_valid
        expect(i.errors[:image_50_x_50].first).to match(/should be \d+x\d+px minimum/)
      end

      # it 'checks mime type' do
      #   skip('fails on qa') if ENV['CI'].present?
      #   #Failure/Error: File.open(path)
      #   #Errno::ENOENT:
      #   #  No such file or directory - /home/runner/LCMC_Portal/tmp/random_file1
      #   ## ./spec/models/user_account_spec.rb:58:in `initialize'
      #   ## ./spec/models/user_account_spec.rb:58:in `open'
      #   ## ./spec/models/user_account_spec.rb:58:in `file_of_size'
      #   ## ./spec/models/user_account_spec.rb:39:in `block (3 levels) in <top (required)>'
      #
      #   user = create(:user)
      #   i = user.build_image
      #   i.image_50_x_50   = file_of_size(1)
      #   i.image_253_x_260 = file_of_size(1)
      #   i.image_277_x_280 = file_of_size(1)
      #   expect(i).not_to be_valid
      #   expect(i.errors[:image_50_x_50].first).to eq('You are not allowed to upload "" files, allowed types: jpg, jpeg, png, bmp')
      # end
      #
      # def file_of_size(megabytes_count)
      #   path = Rails.root.join("tmp/random_file#{megabytes_count}").to_s
      #
      #   unless File.exists?(path)
      #     `dd if=/dev/urandom of=#{path} bs=1M count=1`
      #   end
      #
      #   File.open(path)
      # end
    end
  end

  describe '#us_country?' do
    let(:ua) { build(:us_user_account) }

    it 'US country' do
      expect(ua).to be_us_country
    end

    it 'not US country' do
      ua.country = 'DE'
      expect(ua).not_to be_us_country
    end

    it 'valid country' do
      ua.country = 'UA'
      expect(ua).to be_valid
    end

    it 'not valid country' do
      ua.country = 'wat'
      expect(ua).not_to be_valid
    end
  end
end
