# frozen_string_literal: true

module ActiveAdmin
  module LoggerHelper
    def create_logs
      names = { 'issued_system_credit' => 'credit', 'plutus_debit_amount' => 'object' }
      object = controller_name.classify.underscore
      object = names[object] || object

      if instance_variable_get("@#{object}")
        differences = instance_variable_get("@#{object}").saved_changes.except!(:updated_at)
      end

      if (action_name != 'update' && instance_variable_get("@#{object}").try(:created_at)) || (action_name == 'update' && differences.present?)
        AdminLog.create(admin: current_admin, action: action_name, differences: differences,
                        loggable: instance_variable_get("@#{object}"))
      end
    end
  end
end
