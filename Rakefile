# frozen_string_literal: true

require 'rubocop/rake_task'
require 'rake/testtask'
require 'scraper_test'

RuboCop::RakeTask.new

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
end

ScraperTest::RakeTask.new.install_tasks
task test: 'test:data'

task default: %w[test rubocop]
