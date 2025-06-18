require 'rake/testtask'

namespace :test do
  desc 'Run all tests'
  Rake::TestTask.new(:all) do |t|
    t.libs << 'lib'
    t.libs << 'test'
    t.pattern = 'test/**/test_*.rb'
    t.verbose = false
    t.warning = false
  end
  
  desc 'Run unit tests with coverage'
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task['test:all'].invoke
  end
end

desc 'Run all tests (alias for test:all)'
task test: 'test:all'