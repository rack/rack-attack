# frozen_string_literal: true

def safe_require(name)
  require name
rescue LoadError
  nil
end

require "bundler/setup"

require "logger"
require "minitest/autorun"
require "minitest/pride"
require "rack/test"
safe_require "active_support"
require "rack/attack"

# Simple in-memory cache store for testing without ActiveSupport dependency
class SimpleMemoryStore
  def initialize
    @data = {}
  end

  def read(key)
    entry = @data[key]
    return nil unless entry
    return nil if entry[:expires_at] && entry[:expires_at] < Time.now

    entry[:value]
  end

  def write(key, value, options = {})
    expires_at = options[:expires_in] ? Time.now + options[:expires_in] : nil
    @data[key] = { value: value, expires_at: expires_at }
    true
  end

  def increment(key, amount = 1, options = {})
    current = read(key)
    if current.nil?
      nil
    else
      new_value = current.to_i + amount
      write(key, new_value, options)
      new_value
    end
  end

  def delete(key)
    @data.delete(key)
  end

  def delete_matched(matcher)
    @data.keys.each do |key|
      @data.delete(key) if key.match?(matcher)
    end
  end

  def clear
    @data.clear
  end
end

if RUBY_ENGINE == "ruby"
  require "byebug"
end

safe_require "connection_pool"
safe_require "dalli"
safe_require "rails"
safe_require "redis"
safe_require "redis-store"

class Minitest::Spec
  include Rack::Test::Methods

  before do
    if Object.const_defined?(:Rails) && Rails.respond_to?(:cache) && Rails.cache.respond_to?(:clear)
      Rails.cache.clear
    end
  end

  after do
    Rack::Attack.clear_configuration
    Rack::Attack.instance_variable_set(:@cache, nil)
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
