# frozen_string_literal: true

require "bundler/setup"

require "minitest/autorun"
require "minitest/pride"
require "rspec/mocks/minitest_integration"
require "rack/test"
require "rails"

require "rack/attack"

if RUBY_ENGINE == "ruby"
  require "byebug"
end

def safe_require(name)
  require name
rescue LoadError
  nil
end

safe_require "connection_pool"
safe_require "dalli"
safe_require "redis"
safe_require "redis-activesupport"
safe_require "redis-store"

class MiniTest::Spec
  include Rack::Test::Methods

  before do
    Rails.cache = nil
  end

  after do
    Rack::Attack.clear_configuration
    Rack::Attack.instance_variable_set(:@cache, nil)
    Rack::Attack.instance_variable_set(:@last_failure_at, nil)
    Rack::Attack.error_handler = nil
    Rack::Attack.failure_cooldown = Rack::Attack::DEFAULT_FAILURE_COOLDOWN
    Rack::Attack.ignored_errors = Rack::Attack::DEFAULT_IGNORED_ERRORS.dup
  end

  def app
    Rack::Builder.new do
      # Use Rack::Lint to test that rack-attack is complying with the rack spec
      use Rack::Lint
      # Intentionally added twice to test idempotence property
      use Rack::Attack
      use Rack::Attack
      use Rack::Lint

      run lambda { |_env| [200, {}, ['Hello World']] }
    end.to_app
  end

  def self.it_allows_ok_requests
    it "must allow ok requests" do
      get '/', {}, 'REMOTE_ADDR' => '127.0.0.1'

      _(last_response.status).must_equal 200
      _(last_response.body).must_equal 'Hello World'
    end
  end
end

class Minitest::SharedExamples < Module
  include Minitest::Spec::DSL
end
