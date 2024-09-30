# frozen_string_literal: true

class StaticPagesController < ApplicationController
  http_basic_authenticate_with name: 'demofr', password: 'F@$Nr0x', only: :fashion_rocks

  def product_list
  end

  def fashion_rocks
    render :fashion_rocks, layout: false
  end
end
