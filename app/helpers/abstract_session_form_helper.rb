# frozen_string_literal: true

module AbstractSessionFormHelper
  def error_message(f, attribute)
    message = f.object.errors[attribute.to_sym].first
    return '' if message.blank?

    %(<span class="help-inline">#{message}</span>).html_safe
  end

  def session_submit_button(_form)
    padding_top = @session.persisted? ? '16' : '32'

    result = ''
    result = "#{result}<button style=\"display: none; float: right\" type=\"submit\" class=\"btn btn-primary\" data-form=\"session_form\"></button>"
    result = "#{result}<div class=\"orBlock\" style=\"display: none; float: right; padding: #{padding_top}px 5px; font-size: 13px ; color: #333\">&nbsp;— or — </div>"
    result = "#{result}<button style=\"display: none; float: right\" type=\"submit\" class=\"btn btn-primary\" data-form=\"session_form\"></button>"
    result.html_safe
  end

  private

  def confirm_payment_modal
    raw <<EOL
    <div class="modal autodisplay fade" aria-hidden='true' role='dialog' tabindex='-1'>
      <div class="modal-dialog">
        <div class="modal-content">
          #{render partial: 'become_presenter_steps/close_modal'}
          <div class="modal-body">
            <h1 class="heading">
              Payment
            </h1>

            <p>
              Amount to be charged:
              <strong>#{as_currency(@interactor.charge_amount)}</strong>
            </p>

            <a href="#" class="confirm_payment btn btn-primary">Confirm Payment</a>

            <a data-dismiss='modal' href='' class='btn btn-default'>
              Back
            </a>
          </div>
        </div>
      </div>
    </div>
EOL
  end
end
