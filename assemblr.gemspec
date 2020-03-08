# frozen_string_literal: true

require_relative 'lib/assemblr/version'

Gem::Specification.new do |spec|
  spec.name     = 'assemblr'
  spec.version  = Assemblr::VERSION
  spec.authors  = ['Ryan Burmeister-Morrison']
  spec.email    = ['rburmeistermorrison@gmail.com']

  spec.summary  = 'A small DSL for the construction of quick automation tasks.'
  spec.homepage = 'https://github.com/rburmorrison/assemblr'
  spec.license  = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/rburmorrison/assemblr'

  # Specify which files should be added to the gem when it is released. The `git
  # ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rubocop', '~> 0.80'

  spec.add_runtime_dependency 'net-ping', '~> 2.0'
  spec.add_runtime_dependency 'net-scp', '~> 2.0'
  spec.add_runtime_dependency 'net-ssh', '~> 5.2'
  spec.add_runtime_dependency 'tty-logger', '~> 0.3'
end
