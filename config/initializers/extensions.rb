# frozen_string_literal: true

require File.join(Rails.root, 'lib', 'extensions', 'active_record', 'has_many_documents')

ActiveRecord::Base.include Extensions::ActiveRecord::HasManyDocuments
