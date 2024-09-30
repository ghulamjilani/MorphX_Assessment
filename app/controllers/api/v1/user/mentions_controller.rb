# frozen_string_literal: true

module Api
  module V1
    module User
      class MentionsController < Api::V1::User::ApplicationController
        def index
          q = params[:query]
          raise(ActiveRecord::RecordInvalid, 'query param required') if q.blank?

          query = ::User.not_fake.not_deleted.where('slug ILIKE ?', "%#{q}%")
          @count = query.count
          order_by = %w[slug created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'slug'
          order = %w[asc desc].include?(params[:order]) ? params[:order] : 'asc'
          @mention_suggestions = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
        end
      end
    end
  end
end
