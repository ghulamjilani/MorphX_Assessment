# frozen_string_literal: true

envelope json, (@status || 200), (@modal.pretty_errors if @modal.errors.present?) do
  json.opt_in_modal do
    json.partial! 'api/v1/user/marketing_tools/opt_in_modals/opt_in_modal', opt_in_modal: @modal
  end
end
