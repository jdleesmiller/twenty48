# frozen_string_literal: true

lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)

require 'twenty48/version'

Gem::Specification.new do |s|
  s.name              = 'twenty48'
  s.version           = Twenty48::VERSION
  s.platform          = Gem::Platform::RUBY
  s.authors           = ['John Lees-Miller']
  s.email             = ['jdleesmiller@gmail.com']
  s.homepage          = 'https://github.com/jdleesmiller/twenty48'
  s.summary           = 'Provably optimal solver for 2048-like games.'
  s.description       = 'Provably optimal solver for 2048-like games based on '\
    ' finite Markov Decision Processes.'

  s.add_runtime_dependency 'finite_mdp', '~> 0.3.0'
  s.add_runtime_dependency 'parallel', '~> 1.10.0'

  s.add_development_dependency 'gemma', '~> 5.0.0'
  s.add_development_dependency 'rake-compiler', '~> 1.0.1'
  s.add_development_dependency 'rubocop', '~> 0.51.0'
  s.add_development_dependency 'ruby-prof', '~> 0.15.9'

  s.files = Dir.glob('{lib,bin}/**/*.rb') +
    Dir.glob('ext/**/*.{i,hpp,cxx,rb}') +
    %w[README.md]
  s.extensions = Dir.glob('ext/**/extconf.rb')
  s.test_files  = Dir.glob('test/twenty48/*_test.rb')
  s.executables = Dir.glob('bin/*').map { |f| File.basename(f) }

  s.rdoc_options = [
    '--main',    'README.md',
    '--title',   "#{s.full_name} Documentation"
  ]
  s.extra_rdoc_files << 'README.md'
end
