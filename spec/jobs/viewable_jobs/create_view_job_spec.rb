# frozen_string_literal: true

require 'spec_helper'

describe ViewableJobs::CreateViewJob do
  let(:viewable) { create(%i[recording_published video_published published_livestream_session blog_post_published].sample) }
  let(:user) { create(:user) }
  let(:view_params) do
    JSON.parse(File.read(Rails.root.join('spec/fixtures/views/create_view_job_params.json'))).merge(
      {
        viewable_id: viewable.id,
        viewable_type: viewable.class.name,
        user_id: user.id,
        group_name: viewable.unique_view_group_name(user.id)
      }
    )
  end

  it { expect { described_class.new.perform(view_params) }.not_to raise_error }

  it { expect { described_class.new.perform(view_params) }.to change(View, :count) }

  # it 'updates views count' do
  #   expect do
  #     described_class.new.perform(view_params)
  #     viewable.reload
  #   end.to change(viewable, :views_count).by(1)
  #                                        .and change(viewable, :unique_views_count).by(1)
  # end
end
