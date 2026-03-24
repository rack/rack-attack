# frozen_string_literal: true

require_relative "../spec_helper"
require "minitest/stub_const"

describe "Cache store config when using fail2ban" do
  before do
    Rack::Attack.blocklist("fail2ban pentesters") do |request|
      Rack::Attack::Fail2Ban.filter(request.ip, maxretry: 2, findtime: 30, bantime: 60) do
        request.path.include?("private-place")
      end
    end
  end

  unless defined?(Rails)
    it "gives semantic error if no store was configured" do
      assert_raises(Rack::Attack::MissingStoreError) do
        get "/private-place"
      end
    end
  end

  it "display warning if store is missing methods" do
    warning = "[rack-attack] Configured store Object doesn't respond to #read, #write, #delete, #increment\n"
    assert_output("", warning) do
      Rack::Attack.cache.store = Object.new
    end
  end

  it "works with any object that responds to #read, #write, #delete and #increment" do
    fake_store_class = Class.new do
      attr_accessor :backend

      def initialize
        @backend = {}
      end

      def read(key)
        @backend[key]
      end

      def write(key, value, _options = {})
        @backend[key] = value
      end

      def increment(key, _count, _options = {})
        @backend[key] ||= 0
        @backend[key] += 1
      end

      def delete(key)
        @backend.delete(key)
      end
    end

    Rack::Attack.cache.store = fake_store_class.new

    get "/"
    assert_equal 200, last_response.status

    get "/private-place"
    assert_equal 403, last_response.status

    get "/private-place"
    assert_equal 403, last_response.status

    get "/"
    assert_equal 403, last_response.status
  end
end
