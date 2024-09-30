# frozen_string_literal: true

class Api::V1::Blog::ImagesController < Api::V1::Blog::ApplicationController
  before_action :set_image, only: %i[show update destroy]

  def index
    query = Blog::Post.find(params[:post_id]).blog_images
    @count = query.count
    order_by = %w[created_at updated_at].include?(params[:order_by]) ? params[:order_by] : 'updated_at'
    order = %w[asc desc].include?(params[:order]) ? params[:order] : 'desc'
    @images = query.order(Arel.sql("#{order_by} #{order}")).limit(@limit).offset(@offset)
  end

  def create
    organization = Organization.find(create_image_attributes[:organization_id])
    return render_json(403, 'You are not allowed to create images in this organization') unless current_ability.can?(
      :create_blog_image, organization
    )

    @image = organization.blog_images.build
    @image.attributes = create_image_attributes
    @image.save!
    render :show
  end

  def show
  end

  def update
    return render_json(403, 'You are not allowed to update this image') unless current_ability.can?(:update, @image)

    @image.update!(update_image_attributes)
    render :show
  end

  def destroy
    return render_json(403, 'You are not allowed to destroy this image') unless current_ability.can?(:destroy, @image)

    @image.destroy!
    render :show
  end

  private

  def current_ability
    @current_ability ||= ::AbilityLib::Blog::ImageAbility.new(current_user).merge(::AbilityLib::OrganizationAbility.new(current_user))
  end

  def set_image
    @image = Blog::Image.find(params[:id])
  end

  def create_image_attributes
    params.permit(:organization_id, :blog_post_id, :image)
  end

  def update_image_attributes
    params.permit(:blog_post_id)
  end
end
