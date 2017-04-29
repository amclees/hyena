# frozen_string_literal: true

require 'rake/testtask'
require 'rubocop/rake_task'

Rake::TestTask.new do |task|
  task.libs << 'test'
  task.test_files = FileList['tests/*_tests.rb']
  task.verbose = true
end

RuboCop::RakeTask.new(:rubocop) do |task|
  task.options = ['--display-cop-names']
end

task default: %i[test rubocop]
