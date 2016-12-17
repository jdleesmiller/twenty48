# frozen_string_literal: true
# rubocop:disable Style/GlobalVars

require 'mkmf'

$CXXFLAGS += ' -std=c++11 ' if RUBY_PLATFORM =~ /linux/

create_makefile('twenty48')
