# frozen_string_literal: true

require 'bundler/setup'
require 'English'
require 'gemma'
require 'rake/extensiontask'

NAME = 'twenty48'
EXT_DIR = File.join('ext', NAME)
LIB_DIR = File.join('lib', 'twenty48')

def ext_file(file)
  File.join(EXT_DIR, file)
end

Gemma::RakeTasks.with_gemspec_file 'twenty48.gemspec'

WRAP_FILE = ext_file("#{NAME}_wrap.cxx")
SWIG_FILES = [ext_file("#{NAME}.i")] + Dir.glob(ext_file('*.hpp'))
file WRAP_FILE => SWIG_FILES do
  break if ENV['NOSWIG']
  Dir.chdir(EXT_DIR) do
    system "swig -c++ -ruby #{NAME}.i"
    raise unless $CHILD_STATUS.exitstatus == 0
  end
end

Rake::ExtensionTask.new(NAME) do |ext|
  ext.lib_dir = LIB_DIR
  ext.source_pattern = '*.{c,cxx}'
end

task default: [:compile, :test]
