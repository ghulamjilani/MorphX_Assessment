# frozen_string_literal: true
class PgSearchDocument < PgSearch::Document
  include ModelConcerns::ActiveModel::Extensions

  belongs_to :user
  belongs_to :channel

  belongs_to :searchable_session, class_name: 'Session', foreign_type: 'Session', foreign_key: 'searchable_id', polymorphic: true
  belongs_to :searchable_user, class_name: 'User', foreign_type: 'User', foreign_key: 'searchable_id', polymorphic: true
  belongs_to :searchable_video, class_name: 'Video', foreign_type: 'Video', foreign_key: 'searchable_id', polymorphic: true
  belongs_to :searchable_channel, class_name: 'Channel', foreign_type: 'Channel', foreign_key: 'searchable_id', polymorphic: true
  belongs_to :searchable_recording, class_name: 'Recording', foreign_type: 'Recording', foreign_key: 'searchable_id', polymorphic: true

  pg_search_scope :search_by_title,
                  against: :title,
                  using: {
                    tsearch: {
                      dictionary: 'english',
                      tsvector_column: 'tsv_title',
                      prefix: true
                    }
                  }

  SEARCH_ACCEPT_ATTRS = %i[
    adult
    age_restrictions
    archived
    category_id
    channel_id
    channel_type_id
    created_after
    created_before
    deleted
    duration
    duration_from
    duration_to
    end_after
    end_at
    end_before
    fake
    featured
    free
    immersive_purchase_price
    listed_at
    livestream_purchase_price
    model_created_at
    organization_id
    popularity
    presenter_id
    private
    published
    purchase_price
    recorded_purchase_price
    searchable_type
    show_on_home
    hide_on_home
    show_on_profile
    start_after
    start_at
    start_at_and_duration
    start_before
    status
    user_id
    valid_channels_count
    views_count
    visible
  ].freeze

  BOOL_ATTRS = %i[
    private
    show_on_profile
    show_on_home
    featured
    fake
    visible
    free
    published
    deleted
  ].freeze

  scope :not_private, -> { where(private: [nil, false]) }

  scope :filter_order, lambda { |_params|
    field = _params[:order_by].to_s.to_sym

    if _params[:query].blank? && field == :rank
      field = :views_count
    end

    promo_order = ''
    order = _params[:order] || 'desc'
    order = 'desc' unless %w[desc asc].include?(order)

    query = self

    if _params[:promo_weight].present?
      promo_order = 'promo_weight DESC, '
    end

    if _params[:query].present? && field == :rank
      query.with_pg_search_rank.reorder("#{promo_order}rank #{order}")
    elsif SEARCH_ACCEPT_ATTRS.include?(field)
      query.reorder(Arel.sql("#{promo_order}#{field} #{order}"))
    else
      query.reorder(Arel.sql("#{promo_order}#{SEARCH_ACCEPT_ATTRS.first} #{order}"))
    end
  }

  scope :multisearch_by_params, lambda { |_params = {}|
    if _params.is_a? ActionController::Parameters
      _params = _params.permit!.to_h
    end
    _params = _params.with_indifferent_access

    if _params[:searchable_type].present?
      case _params[:searchable_type]
      when 'User', 'Channel'
        _params = _params.except(:created_after, :created_before, :duration_from, :duration_to)
      end
      _params[:searchable_type] = _params[:searchable_type].split(',')
    end

    query = where(nil)

    if _params[:created_after] && _params[:created_before]
      query = query.where(listed_at: _params[:created_after].._params[:created_before])
    elsif _params[:created_after]
      query = query.where('listed_at >= ?', _params[:created_after])
    elsif _params[:created_before]
      query = query.where('listed_at <= ?', _params[:created_before])
    end

    if _params[:start_after] && _params[:start_before]
      query = query.where(start_at: _params[:start_after].._params[:start_before])
    elsif _params[:start_after]
      query = query.where('start_at >= ?', _params[:start_after])
    elsif _params[:start_before]
      query = query.where('start_at <= ?', _params[:start_before])
    end

    if _params[:end_after] && _params[:end_before]
      query = query.where(end_at: _params[:end_after].._params[:end_before])
    elsif _params[:end_after]
      query = query.where('end_at >= ?', _params[:end_after])
    elsif _params[:end_before]
      query = query.where('end_at <= ?', _params[:end_before])
    end

    if _params[:duration_from] && _params[:duration_to]
      query = query.where(duration: _params[:duration_from].._params[:duration_to])
    elsif _params[:duration_from]
      query = query.where('duration >= ?', _params[:duration_from])
    elsif _params[:duration_to]
      query = query.where('duration <= ?', _params[:duration_to])
    end

    excluded_attrs = %i[
      model_created_at
      created_after
      created_before
      start_at
      start_after
      start_before
      end_at
      end_after
      end_before
      duration
      duration_from
      duration_to
      user_id
    ]

    (SEARCH_ACCEPT_ATTRS - excluded_attrs).each do |attr|
      unless _params[attr].nil?
        query = query.where(attr.to_s.to_sym => _params[attr])
      end
    end

    if _params[:user_id].present?
      _params[:user_id] = _params[:user_id].split(',')
      query = query.where(user_id: _params[:user_id])
    end

    query.filter_order(_params)
  }
end
