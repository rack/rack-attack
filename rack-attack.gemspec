# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'rack/attack/version'

Gem::Specification.new do |s|
  s.name = 'rack-attack'
  s.version = Rack::Attack::VERSION

  s.authors = ["Aaron Suggs"]
  s.description = "A rack middleware for throttling and blocking abusive requests"
  s.email = "aaron@ktheory.com"

  s.files = Dir.glob("{bin,lib}/**/*") + %w(Rakefile README.md)
  s.homepage = 'http://github.com/kickstarter/rack-attack'
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.summary = %q{Block & throttle abusive requests}
  s.test_files = Dir.glob("spec/**/*")

  s.required_ruby_version = '>= 1.9.2' # Maybe less?

  s.add_dependency 'rack'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'activesupport', '>= 3.0.0'
  s.add_development_dependency 'debugger', '~> 1.5' unless RUBY_PLATFORM =~ /java/
  s.add_development_dependency 'redis-activesupport'
  s.add_development_dependency 'dalli'
end

