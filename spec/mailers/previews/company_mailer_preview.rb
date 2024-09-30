# frozen_string_literal: true

class CompanyMailerPreview < ApplicationMailerPreview
  def employee_invited
    ::CompanyMailer.employee_invited OrganizationMembership.order(Arel.sql('random()')).pick(:id)
  end

  def employee_rejected
    ::CompanyMailer.employee_rejected User.order(Arel.sql('random()')).pick(:id), Organization.order(Arel.sql('random()')).pick(:id)
  end
end
