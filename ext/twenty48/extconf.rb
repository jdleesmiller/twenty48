# frozen_string_literal: true
# rubocop:disable Style/GlobalVars

require 'mkmf'

$CXXFLAGS += ' -std=c++11 '
$CXXFLAGS += ' -fno-omit-frame-pointer ' if ENV['PERF']

create_makefile('twenty48')
