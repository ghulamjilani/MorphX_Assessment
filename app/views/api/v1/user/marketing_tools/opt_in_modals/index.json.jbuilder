# frozen_string_literal: true

envelope json do
  json.opt_in_modals do
    json.array! @modals do |opt_in_modal|
      json.partial! 'api/v1/user/marketing_tools/opt_in_modals/opt_in_modal', opt_in_modal: opt_in_modal
    end
  end
end
