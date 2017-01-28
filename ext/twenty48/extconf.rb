# frozen_string_literal: true
# rubocop:disable Style/GlobalVars

require 'mkmf'

$CFLAGS += ' -mavx '
$CXXFLAGS += ' -std=c++11 -mavx '
$CXXFLAGS += ' -fno-omit-frame-pointer ' if ENV['PERF']

# On Linux, it defaults to -O2, but -O3 still tests out OK.
$CXXFLAGS.gsub!(/-O2/, '-O3')

create_makefile('twenty48')
