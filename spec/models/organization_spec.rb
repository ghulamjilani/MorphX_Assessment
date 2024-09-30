# frozen_string_literal: true
require 'spec_helper'
require 'sidekiq/testing'

describe Organization do
  let(:organization) { create(:organization) }

  describe 'slug validation' do
    it 'validates slug cross model uniqueness' do
      user = create(:user, first_name: 'Unique', last_name: 'Slug', slug: 'unique-slug')
      expect(user.slug).to eq('unique-slug')
      organization = create(:organization, name: 'Unique Slug')
      expect(organization.slug).not_to eq(user.slug)
    end
  end

  describe '#tags' do
    let(:channel1) { create(:listed_channel, tag_list: nil, organization: organization) }
    let(:channel2) { create(:listed_channel, tag_list: nil, organization: organization) }

    it 'works' do
      channel1.tag_list.add('some_tag')
      channel1.save

      channel2.tag_list.add('some_tag')
      channel2.save

      channel2.tag_list.add('another_tag')
      channel2.save

      expect(ActsAsTaggableOn::Tagging.where(taggable_type: 'Channel').count).to eq(3)
      expect(organization.tags.count).to eq(2)
      expect(organization.tags.first).to be_kind_of(ActsAsTaggableOn::Tag)
    end
  end

  describe '#user_followers' do
    let(:user1) { create(:user) }

    it 'does not fail' do
      user1.follow(organization)

      expect(organization.user_followers).to eq([user1])
    end
  end

  describe '#logo_link' do
    context 'when organization has no channels' do
      context 'when logo_channel_link is disabled in company settings' do
        let(:company_setting) { create(:company_setting, organization: organization, logo_channel_link: false) }

        context 'when no user given' do
          it { expect { company_setting.organization.logo_link }.not_to raise_error }

          it { expect(company_setting.organization.logo_link).to eq('/') }
        end

        context 'when given random user' do
          let(:current_user) { create(:user) }

          it { expect { company_setting.organization.logo_link(current_user) }.not_to raise_error }

          it { expect(company_setting.organization.logo_link(current_user)).to eq('/') }
        end
      end

      context 'when logo_channel_link is enabled in company settings' do
        let(:company_setting) { create(:company_setting, organization: organization) }

        context 'when no user given' do
          it { expect { company_setting.organization.logo_link }.not_to raise_error }

          it { expect(company_setting.organization.logo_link).to eq('/') }
        end

        context 'when given random user' do
          let(:current_user) { create(:user) }

          it { expect { company_setting.organization.logo_link(current_user) }.not_to raise_error }

          it { expect(company_setting.organization.logo_link(current_user)).to eq('/') }
        end
      end
    end

    context 'when organization has multiple channels with default one' do
      let(:default_channel) { create(:listed_channel, organization: organization, is_default: true) }
      let(:not_default_channel) { create(:listed_channel, organization: organization, is_default: false) }

      before do
        default_channel
        not_default_channel
      end

      context 'when logo_channel_link is disabled in company settings' do
        let(:company_setting) { create(:company_setting, organization: organization, logo_channel_link: false) }

        context 'when no user given' do
          it { expect { company_setting.organization.logo_link }.not_to raise_error }

          it { expect(company_setting.organization.logo_link).to eq('/') }
        end

        context 'when given random user' do
          let(:current_user) { create(:user) }

          it { expect { company_setting.organization.logo_link(current_user) }.not_to raise_error }

          it { expect(company_setting.organization.logo_link(current_user)).to eq('/') }
        end
      end

      context 'when logo_channel_link is enabled in company settings' do
        let(:company_setting) { create(:company_setting, organization: organization) }

        context 'when no user given' do
          it { expect { company_setting.organization.logo_link }.not_to raise_error }

          it { expect(company_setting.organization.logo_link).to eq(default_channel.relative_path) }
        end

        context 'when given random user' do
          let(:current_user) { create(:user) }

          it { expect { company_setting.organization.logo_link(current_user) }.not_to raise_error }

          it { expect(company_setting.organization.logo_link(current_user)).to eq(default_channel.relative_path) }
        end

        context 'when default channel is archived' do
          let(:default_channel) { create(:listed_channel, organization: organization, is_default: true, archived_at: 1.minute.ago) }

          it { expect { company_setting.organization.logo_link }.not_to raise_error }

          it { expect(company_setting.organization.logo_link).to eq(not_default_channel.relative_path) }
        end
      end
    end
  end

  describe '#presenter_users' do
    it 'works' do
      organization = create(:organization)
      expect(organization.presenter_users).to be_blank

      membership1 = create(:organization_membership, role: OrganizationMembership::Roles::PRESENTER,
                                                     organization: organization)
      create(:organization_membership, role: OrganizationMembership::Roles::ADMINISTRATOR, organization: organization)

      expect(organization.presenter_users).to eq([membership1.user])

      channel = create(:listed_channel, organization: organization)
      presentership1 = create(:channel_invited_presentership,
                              status: ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED, channel: channel)

      expect(organization.presenter_users.order('users.id ASC')).to eq([presentership1.user, membership1.user].sort)
    end
  end

  context 'when slug changes' do
    let!(:video) { create(:video_published_on_listed_channel) }
    let!(:channel) { video.channel }
    let!(:organization) { channel.organization }
    let!(:recording) { create(:recording, channel: channel) }

    it 'updates slugs for all nested entities' do
      expect do
        Sidekiq::Testing.inline! do
          organization.name = 'New Name'
          organization.save
        end
        organization.reload
        channel.reload
        video.reload
        recording.reload
      end.to(change(organization, :slug).and(change(channel, :slug)))
    end

    it 'updates shortened urls for all nested entities' do
      Sidekiq::Testing.inline! do
        organization.name = 'New Name'
        organization.save
      end
      organization.reload
      channel.reload
      video.reload
      recording.reload

      channel_shortened_url = Shortener::ShortenedUrl.find_by(url: channel.absolute_path)
      expect(channel_shortened_url).not_to be_nil
      expect(channel.short_url).to include(channel_shortened_url.unique_key)

      video_shortened_url = Shortener::ShortenedUrl.find_by(url: video.absolute_path)
      expect(video_shortened_url).not_to be_nil
      expect(video.short_url).to include(video_shortened_url.unique_key)

      # recording_shortened_url = Shortener::ShortenedUrl.find_by(url: recording.absolute_path)
      # expect(recording_shortened_url).not_to be_nil
      # expect(recording.short_url).to include(recording_shortened_url.unique_key)
    end
  end

  describe '#ready_for_wa?' do
    let(:organization_ready_for_wa) { create(:listed_channel).organization }
    let(:organization_not_ready_for_wa) { create(:pending_channel).organization }

    context 'when organization is ready to get assigned with wa' do
      it 'returns correct value' do
        expect(organization_ready_for_wa.ready_for_wa?).to eq(true)
      end
    end

    context 'when organization is not ready to get assigned with wa' do
      it 'returns correct value' do
        expect(organization_not_ready_for_wa.ready_for_wa?).to eq(false)
      end
    end
  end

  describe '#assign_ffmpegservice_account' do
    let!(:wa) { create(:ffmpegservice_account_free_push) }
    let!(:wa1) { create(:ffmpegservice_account_free_push) }
    let(:organization_ready_for_wa) { create(:listed_channel).organization }
    let(:organization_not_ready_for_wa) { create(:pending_channel).organization }

    context 'when organization is ready for wa' do
      it 'assignes wa to organization' do
        expect { organization_ready_for_wa.assign_ffmpegservice_account(current_service: 'main', type: 'free') }
          .to(change { organization_ready_for_wa.ffmpegservice_accounts.main_free.count })
      end
    end

    context 'when organization is not ready for wa' do
      it 'does not assign wa to organization' do
        expect { organization_not_ready_for_wa.assign_ffmpegservice_account(current_service: 'main', type: 'free') }
          .not_to(change { organization_not_ready_for_wa.ffmpegservice_accounts.main_free.count })
      end
    end
  end
end
