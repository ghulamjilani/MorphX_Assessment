# frozen_string_literal: true

class BecomePresenter::SaveCompany
  def initialize(user, company_attributes)
    @user = user
    @company_attributes = company_attributes
    @company = @user.organization || @user.build_organization
    @errors = []
  end

  def execute
    @company.attributes = @company_attributes
    if @company.save
      # Auto assign channels to company
      @user.channels.update_all(organization_id: @company.id, presenter_id: nil)
      true
    else
      Rails.logger.debug errors
      false
    end
  end

  attr_reader :company

  def errors
    @errors << @company.errors.full_messages if @company.errors.present?
    @errors.flatten.compact.uniq.join('. ')
  end
end
