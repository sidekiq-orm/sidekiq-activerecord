# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidekiq/active_record/version'

Gem::Specification.new do |spec|
  spec.name          = 'sidekiq-activerecord'
  spec.version       = Sidekiq::ActiveRecord::VERSION
  spec.authors       = ['Adam Farhi']
  spec.email         = ['afarhi@ebay.com']
  spec.summary       = 'Encapsulates various interactions between Sidekiq and ActiveRecord'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/yelled3/sidekiq-activerecord'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ['lib']

  spec.add_dependency 'sidekiq',   '>= 2.16'
  spec.add_dependency 'activerecord', '>= 4.0'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '3.0.0.rc1'
  spec.add_development_dependency 'database_cleaner', '>= 1.2.0'
  spec.add_development_dependency 'factory_girl', '~> 4.0'
end
