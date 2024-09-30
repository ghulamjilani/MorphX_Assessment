# frozen_string_literal: true

module CommentsHelper
  def review_action_title(model = nil)
    model = model || @session || @abstract_session
    # could be easily cached
    has_comment = Comment.where(commentable_type: model.class.to_s, commentable_id: model.id,
                                user: current_user).first.present?

    has_comment ? 'Update feedback' : 'Leave feedback'
  end

  def comment_submit_button(form)
    if current_user.confirmed?
      raw form.action(:submit,
                      as: :button,
                      label: review_action_title,
                      button_html: {
                        class: 'btn btn-l',
                        id: 'post-review',
                        data: { disable_with: 'Please wait…' }
                      }.tap do |h|
                        unless can?(:create_or_update_review_comment, @session)
                          h[:disabled] = 'disabled'
                        end
                      end)
    else
      raw form.action(:submit,
                      as: :button,
                      label: review_action_title,
                      button_html: {
                        class: 'btn btn-l',
                        id: 'post-review',
                        onclick: %(alert("#{I18n.t('reviews.can_not_comment_before_email_confirmation_message')}"); return false)
                      })
    end
  end
end
