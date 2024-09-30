# frozen_string_literal: true

require 'swagger_helper'

describe 'HomeBanners', swagger_doc: 'api/v1/swagger.json' do
  path '/api/v1/user/page_builder/home_banners' do
    post 'Create Home Banner' do
      tags 'User::PageBuilder::HomeBanners'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :'image[crop_x]', in: :query, type: :float, example: '3.232332'
      parameter name: :'image[crop_y]', in: :query, type: :float, example: '3.232332'
      parameter name: :'image[crop_w]', in: :query, type: :float, example: '3.232332'
      parameter name: :'image[crop_h]', in: :query, type: :float, example: '3.232332'
      parameter name: :'image[rotate]', in: :query, type: :integer, example: '90'
      parameter name: :file, in: :formData, type: :file, description: 'Image file'
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end

  path '/api/v1/user/page_builder/home_banners/{id}' do
    get 'Show Home Banner' do
      tags 'User::PageBuilder::HomeBanners'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :name, in: :query, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end

    delete 'Destroy Home Banner' do
      tags 'User::PageBuilder::HomeBanners'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :name, in: :query, type: :string, required: true
      produces 'application/json'
      response '200', 'Found' do
        run_test!
      end
    end
  end
end
