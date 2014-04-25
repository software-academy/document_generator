# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'document_generator/version'

Gem::Specification.new do |spec|
  spec.name          = 'document_generator'
  spec.version       = DocumentGenerator::VERSION
  spec.authors       = ['wiscoDude', 'm5rk', 'software-academy']
  spec.email         = ['philip.harry@gmail.com', 'mark.mceahern@gmail.com']
  spec.description   = <<-DOCUMENT_GENERATOR
Generate documentation from a git repository.
DOCUMENT_GENERATOR
  spec.summary       = 'Generate documentation from a git repository.'
  spec.homepage      = 'http://github.com/software-academy/document_generator'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'addressable', '~> 2.3'
  spec.add_runtime_dependency 'git', '~> 1.2'
  spec.add_runtime_dependency 'octokit', '~> 2.0'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 2.14'
  spec.add_development_dependency 'rspec-fire', '~> 1.3'
  spec.add_development_dependency 'simplecov', '~> 0.7'
  spec.add_development_dependency 'pry'
end
