# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fig_tree/version'

Gem::Specification.new do |spec|
  spec.name          = 'fig_tree'
  spec.version       = FigTree::VERSION
  spec.authors       = ['Daniel Orner']
  spec.email         = ['daniel.orner@flipp.com']
  spec.summary       = 'Configuration framework for Ruby.'
  spec.homepage      = ''
  spec.license       = 'Apache-2.0'
  spec.required_ruby_version = '2.3'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency('activesupport', '>= 3.0.0')

  spec.add_development_dependency('guard', '~> 2')
  spec.add_development_dependency('guard-rspec', '~> 4')
  spec.add_development_dependency('guard-rubocop', '~> 1')
  spec.add_development_dependency('rspec', '~> 3')
  spec.add_development_dependency('rspec_junit_formatter', '~>0.3')
  spec.add_development_dependency('rubocop', '~> 0.72')
  spec.add_development_dependency('rubocop-rspec', '~> 1.27')
end
