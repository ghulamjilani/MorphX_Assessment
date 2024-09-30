# frozen_string_literal: true
class OrganizerAbstractSessionPayPromise < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :co_presenter, class_name: 'Presenter', touch: true
  belongs_to :abstract_session, polymorphic: true, touch: true

  validates :abstract_session_id, uniqueness: { scope: %i[co_presenter_id abstract_session_type] }
  before_destroy :cant_remove, if: :abstract_session

  private

  def cant_remove
    # cant_remove does not belong to this model, it has to be on a higher level(interactor? ability?)
    # the reason why it is not removed(yet) is that we're trying to catch it locally to migrate it properly to a higher level
    return if Rails.env.qa? || Rails.env.production?

    if abstract_session.invited_co_presenter_status(co_presenter) == ModelConcerns::ActsAsInvitableAbstractSessionPerson::Statuses::ACCEPTED
      raise ActiveRecord::Rollback
    end
  end
end
