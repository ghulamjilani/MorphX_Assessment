# frozen_string_literal: true

namespace :ci do
  desc 'Prepare for CI and run entire test suite'
  task :prepare do
    Rails.env = 'test'

    require 'benchmark'

    Benchmark.bm(27) do |bm|
      bm.report('db prepare step') do
        Rake::Task['db:create'].invoke
        Rake::Task['db:migrate'].invoke
        Rake::Task['db:test:prepare'].invoke
        Rake::Task['db:test:load'].invoke
      end
    end
  end

  desc 'build for CI and run entire test suite'
  task :build do
    sh './bin/rspec'
  end

  desc 'Prepare for CI and run entire test suite'
  task run: ['ci:prepare', 'ci:build'] do
    # Prepare for CI and run entire test suite
  end
end
