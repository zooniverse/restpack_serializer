# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'restpack_serializer/version'

Gem::Specification.new do |gem|
  gem.name          = "restpack_serializer"
  gem.version       = RestPack::Serializer::VERSION
  gem.authors       = ["Gavin Joyce"]
  gem.email         = ["gavinjoyce@gmail.com"]
  gem.description   = %q{Model serialization, paging, side-loading and filtering}
  gem.summary       = %q{Model serialization, paging, side-loading and filtering}
  gem.homepage      = "https://github.com/RestPack"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'activesupport', '< 8'
  gem.add_dependency 'activerecord', '< 8'

  # Concurrent Ruby 1.3.5+ does not work well with ActiveRecord/ActiveSupport v7.0 and lower
  gem.add_dependency 'concurrent-ruby', '1.3.4'
  gem.add_dependency 'kaminari', '< 2.0'

  gem.add_development_dependency 'restpack_gem', '~> 0.0.9'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'factory_bot', '6.4.4'
  gem.add_development_dependency 'sqlite3'
  gem.add_development_dependency 'database_cleaner', '~> 1.0.1'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'bump'
  gem.add_development_dependency 'protected_attributes_continued'
end
