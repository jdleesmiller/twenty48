# -*- encoding: utf-8 -*-
# frozen_string_literal: true

lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'twenty_48/version'

Gem::Specification.new do |s|
  s.name              = 'twenty_48'
  s.version           = Twenty48::VERSION
  s.platform          = Gem::Platform::RUBY
  s.authors           = ['John Lees-Miller']
  s.email             = ['jdleesmiller@gmail.com']
  s.homepage          = 'https://github.com/jdleesmiller/twenty_48'
  s.summary           = 'Provably optimal solver for 2048-like games.'
  s.description       = 'Provably optimal solver for 2048-like games based on '\
    ' finite Markov Decision Processes.'

  s.add_runtime_dependency 'finite_mdp', '~> 0.2.0'

  s.add_development_dependency 'gemma', '~> 4.1.0'
  s.add_development_dependency 'ruby-prof', '~> 0.15.9'
  s.add_development_dependency 'rubocop', '~> 0.42.0'

  s.files       = Dir.glob('{lib,bin}/**/*.rb') + %w(README.md)
  s.test_files  = Dir.glob('test/twenty_48/*_test.rb')
  s.executables = Dir.glob('bin/*').map { |f| File.basename(f) }

  s.rdoc_options = [
    '--main',    'README.md',
    '--title',   '#{s.full_name} Documentation'
  ]
  s.extra_rdoc_files << 'README.md'
end
