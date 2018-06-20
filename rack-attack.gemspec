# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'rack/attack/version'

Gem::Specification.new do |s|
  s.name = 'rack-attack'
  s.version = Rack::Attack::VERSION
  s.license = 'MIT'

  s.authors = ["Aaron Suggs"]
  s.description = "A rack middleware for throttling and blocking abusive requests"
  s.email = "aaron@ktheory.com"

  s.files = Dir.glob("{bin,lib}/**/*") + %w(Rakefile README.md)
  s.homepage = 'https://github.com/kickstarter/rack-attack'
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.summary = %q{Block & throttle abusive requests}
  s.test_files = Dir.glob("spec/**/*")

  s.required_ruby_version = '>= 2.2'

  s.add_dependency 'rack'

  s.add_development_dependency 'actionpack', '>= 3.0.0'
  s.add_development_dependency 'activesupport', '>= 3.0.0'
  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'connection_pool'
  s.add_development_dependency 'dalli'
  s.add_development_dependency 'guard-minitest'
  s.add_development_dependency 'memcache-client'
  s.add_development_dependency 'minitest'
  s.add_development_dependency "minitest-stub-const"
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'redis-activesupport'
  s.add_development_dependency "rubocop", "0.57.2"
  s.add_development_dependency "timecop"

  # Need to explicitly depend on guard because guard-minitest doesn't declare
  # the dependency intentionally
  #
  # See https://github.com/guard/guard-minitest/pull/131
  s.add_development_dependency 'guard'

  # byebug only works with MRI
  if RUBY_ENGINE == "ruby"
    s.add_development_dependency 'byebug'
  end
end
