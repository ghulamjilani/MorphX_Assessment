# frozen_string_literal: true

require 'aws-sdk-s3'

if Rails.env.development?
  # Aws.config.update({
  #                       region: 'us-east-1',
  #                       credentials: Aws::Credentials.new(ENV['S3_ACCESS_KEY_ID'], ENV['S3_SECRET_ACCESS_KEY'])
  #                   })
else
  Aws.config.update({
                      region: 'us-west-2',
                      credentials: Aws::Credentials.new(ENV['S3_ACCESS_KEY_ID'], ENV['S3_SECRET_ACCESS_KEY'])
                    })
end
