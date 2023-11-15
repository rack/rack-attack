# frozen_string_literal: true

require_relative 'lib/rack/attack/version'

Gem::Specification.new do |s|
  s.name = 'rack-attack'
  s.version = Rack::Attack::VERSION
  s.license = 'MIT'

  s.authors = ["Aaron Suggs"]
  s.description = "A rack middleware for throttling and blocking abusive requests"
  s.email = "aaron@ktheory.com"

  s.files = Dir.glob("{bin,lib}/**/*") + %w(Rakefile README.md LICENSE)
  s.homepage = 'https://github.com/rack/rack-attack'
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.summary = 'Block & throttle abusive requests'
  s.test_files = Dir.glob("spec/**/*")

  s.metadata = {
    "bug_tracker_uri" => "https://github.com/rack/rack-attack/issues",
    "changelog_uri" => "https://github.com/rack/rack-attack/blob/main/CHANGELOG.md",
    "source_code_uri" => "https://github.com/rack/rack-attack"
  }

  s.required_ruby_version = '>= 2.4'

  s.add_runtime_dependency 'rack', ">= 1.0", "< 4"

  s.add_development_dependency 'appraisal', '~> 2.2'
  s.add_development_dependency "bundler", ">= 1.17", "< 3.0"
  s.add_development_dependency 'minitest', "~> 5.11"
  s.add_development_dependency "minitest-stub-const", "~> 0.6"
  s.add_development_dependency 'rack-test', "~> 2.0"
  s.add_development_dependency 'rake', "~> 13.0"
  s.add_development_dependency "rubocop", "1.12.1"
  s.add_development_dependency "rubocop-minitest", "~> 0.11.1"
  s.add_development_dependency "rubocop-performance", "~> 1.10.2"
  s.add_development_dependency "rubocop-rake", "~> 0.5.1"
  s.add_development_dependency "timecop", "~> 0.9.1"

  # byebug only works with MRI
  if RUBY_ENGINE == "ruby"
    s.add_development_dependency 'byebug', '~> 11.0'
  end

  s.add_development_dependency "activesupport"
end
