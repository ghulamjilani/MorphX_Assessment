# frozen_string_literal: true

PgSearch.multisearch_options = {
  using: {
    # trigram: {
    #   threshold: 0.1
    # },
    tsearch: {
      tsvector_column: 'tsv',
      prefix: true,
      dictionary: 'english',
      negation: true
    }
  }
}
