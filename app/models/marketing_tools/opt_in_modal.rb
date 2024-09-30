# frozen_string_literal: true
class MarketingTools::OptInModal < MarketingTools::ApplicationRecord
  belongs_to :channel, class_name: 'Channel', inverse_of: :opt_in_modals, foreign_key: :channel_uuid, primary_key: :uuid
  belongs_to :system_template, class_name: 'PageBuilder::SystemTemplate', inverse_of: :opt_in_modal, foreign_key: :pb_system_template_id, primary_key: :id, dependent: :destroy
  has_many :opt_in_modal_submits, class_name: 'MarketingTools::OptInModalSubmit', inverse_of: :opt_in_modal, foreign_key: :mrk_tools_opt_in_modal_id, primary_key: :id, dependent: :destroy

  accepts_nested_attributes_for :system_template, update_only: true

  scope :for_model, lambda { |model_type, model_id|
    model_type.capitalize!
    channel = case model_type
              when 'Channel'
                Channel.find(model_id)
              when 'Video', 'Recording', 'Session'
                model_type.constantize.find(model_id).channel
              else
                raise 'Invalid Model Type'
              end
    where(channel_uuid: channel.uuid)
  }
end
