# frozen_string_literal: true

require "bundler/gem_tasks"

# Load all rake tasks from the tasks directory
Dir.glob('tasks/**/*.rake').each { |r| load r }

desc 'Run tests with code coverage'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['test:all'].invoke
end

task default: 'test:all'