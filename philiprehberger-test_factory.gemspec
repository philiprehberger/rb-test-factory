# frozen_string_literal: true

require_relative 'lib/philiprehberger/test_factory/version'

Gem::Specification.new do |spec|
  spec.name = 'philiprehberger-test_factory'
  spec.version = Philiprehberger::TestFactory::VERSION
  spec.authors = ['Philip Rehberger']
  spec.email = ['me@philiprehberger.com']

  spec.summary = 'Lightweight test data factory DSL with sequences and traits'
  spec.description = 'Lightweight DSL for building test data objects without ActiveRecord. ' \
                       'Define factories with default attributes, apply traits for variations, ' \
                       'and use thread-safe sequences for unique values.'
  spec.homepage = 'https://philiprehberger.com/open-source-packages/ruby/philiprehberger-test_factory'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/philiprehberger/rb-test-factory'
  spec.metadata['changelog_uri'] = 'https://github.com/philiprehberger/rb-test-factory/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri'] = 'https://github.com/philiprehberger/rb-test-factory/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
