require 'rake'
require 'rake/testtask'
require 'fileutils'

task :default => [:test]

Rake::TestTask.new do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end