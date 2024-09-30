# frozen_string_literal: true

module Log
  class Activity
    include ::Mongoid::Document
    include ::Mongoid::Timestamps
    include ::Mongoid::Attributes::Dynamic if ::Mongoid::VERSION.split('.')[0].to_i >= 4
    include ModelConcerns::Mongoid::ActiveRecordBridge
    store_in collection: 'log_activities'

    opts = if ::Mongoid::VERSION.split('.')[0].to_i >= 7
             { polymorphic: true, optional: false }
           else
             { polymorphic: true }
           end

    # Define polymorphic association to the parent
    belongs_to_record :trackable, opts
    # Define ownership to a resource responsible for this activity
    belongs_to_record :owner, opts
    # Define ownership to a resource targeted by this activity
    belongs_to_record :recipient, opts

    field :key,         type: String
    field :parameters,  type: Hash

    index({ updated_at: -1 })
    index({ trackable_id: 1, trackable_type: 1 })
    index({ owner_id: 1, owner_type: 1 })
    index({ recipient_id: 1, recipient_type: 1 })
  end
end
