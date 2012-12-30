# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'soft_active/version'

Gem::Specification.new do |gem|
  gem.name          = "soft_active"
  gem.version       = SoftActive::VERSION
  gem.authors       = ["Sushant Mohanty"]
  gem.email         = ["smohanty@mohantyfamily.org"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  # add dependencies
  gem.add_development_dependency "rspec"
  gem.add_dependency "activerecord", "~> 3.2"
end
