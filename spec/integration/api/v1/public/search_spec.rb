# frozen_string_literal: true

require 'swagger_helper'

describe 'Search', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/public/search' do
    get 'Global Search' do
      tags 'Public::Search'
      produces 'application/json'
      parameter name: :query, in: :query, type: :string
      parameter name: :promo_weight, in: :query, type: :integer
      parameter name: :search_by, in: :query, type: :string,
                description: 'Available options: "title". Othervise search will be performed through all data'
      parameter name: :limit, in: :query, type: :integer
      parameter name: :offset, in: :query, type: :integer
      parameter name: :order_by, in: :query, type: :string, description: "Valid values are: #{PgSearchDocument::SEARCH_ACCEPT_ATTRS.map do |s|
                                                                                                "'#{s}'"
                                                                                              end.join(', ')}. Default: '#{PgSearchDocument::SEARCH_ACCEPT_ATTRS.first}'"
      parameter name: :order, in: :query, type: :string, description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
      PgSearchDocument::SEARCH_ACCEPT_ATTRS.each do |attr|
        parameter name: attr, in: :query, type: (PgSearchDocument::BOOL_ATTRS.include? attr ? :boolean : :string)
      end

      response '200', 'Found' do
        run_test!
      end
    end
  end

  %w[users channels sessions videos recordings blog/posts].each do |entity|
    path "/api/v1/public/search/#{entity}" do
      get "#{entity.titleize} Search" do
        tags 'Public::Search'
        produces 'application/json'
        parameter name: :query, in: :query, type: :string
        parameter name: :promo_weight, in: :query, type: :integer
        parameter name: :search_by, in: :query, type: :string,
                  description: 'Available options: "title". Othervise search will be performed through all data'
        parameter name: :limit, in: :query, type: :integer
        parameter name: :offset, in: :query, type: :integer
        parameter name: :order_by, in: :query, type: :string, description: "Valid values are: #{PgSearchDocument::SEARCH_ACCEPT_ATTRS.map do |s|
                                                                                                  "'#{s}'"
                                                                                                end.join(', ')}. Default: '#{PgSearchDocument::SEARCH_ACCEPT_ATTRS.first}'"
        parameter name: :order, in: :query, type: :string,
                  description: "Valid values are: 'asc', 'desc'. Default: 'desc'"
        PgSearchDocument::SEARCH_ACCEPT_ATTRS.each do |attr|
          parameter name: attr, in: :query, type: (PgSearchDocument::BOOL_ATTRS.include? attr ? :boolean : :string)
        end

        response '200', 'Found' do
          run_test!
        end
      end
    end
  end
end
