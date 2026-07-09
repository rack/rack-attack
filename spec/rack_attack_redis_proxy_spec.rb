# frozen_string_literal: true

require_relative 'spec_helper'

module RedisProxySpec
  class FakeRedis
    class Error < StandardError; end

    attr_reader :calls

    def initialize(raises: nil)
      @raises = raises
      @calls = []
    end

    def get(key)
      record(:get, key)
    end

    def set(key, value)
      record(:set, [key, value])
    end

    def setex(key, expires_in, value)
      record(:setex, [key, expires_in, value])
    end

    def del(*keys)
      record(:del, keys)
    end

    def pipelined
      record(:pipelined)
      yield(self) if block_given?
      [1]
    end

    def incrby(key, amount)
      record(:incrby, [key, amount])
    end

    def expire(key, ttl)
      record(:expire, [key, ttl])
    end

    def scan(_cursor, **_opts)
      ["0", []]
    end

    def record(method, args = nil)
      @calls << [method, args]
      raise @raises if @raises

      :ok
    end
  end
end

describe Rack::Attack::StoreProxy::RedisProxy do
  before do
    skip 'redis gem not available' unless defined?(::Redis)
  end

  it "declares its default as ['Redis::BaseConnectionError']" do
    _(Rack::Attack::StoreProxy::RedisProxy.default_bypassable_store_errors)
      .must_equal ['Redis::BaseConnectionError']
  end

  it "bypasses Redis::BaseConnectionError by default on #read" do
    redis = RedisProxySpec::FakeRedis.new(raises: Redis::BaseConnectionError.new("down"))
    proxy = Rack::Attack::StoreProxy::RedisProxy.new(redis)
    _(proxy.read("k")).must_be_nil
  end

  it "bypasses Redis::BaseConnectionError subclasses on #write" do
    redis = RedisProxySpec::FakeRedis.new(raises: Redis::CannotConnectError.new("down"))
    proxy = Rack::Attack::StoreProxy::RedisProxy.new(redis)
    _(proxy.write("k", "v")).must_be_nil
  end

  it "re-raises other errors by default" do
    redis = RedisProxySpec::FakeRedis.new(raises: RuntimeError.new("boom"))
    proxy = Rack::Attack::StoreProxy::RedisProxy.new(redis)
    _(-> { proxy.read("k") }).must_raise RuntimeError
  end

  it "bypasses custom errors when configured" do
    redis = RedisProxySpec::FakeRedis.new(raises: RedisProxySpec::FakeRedis::Error.new("oom"))
    proxy = Rack::Attack::StoreProxy::RedisProxy.new(
      redis,
      bypassable_store_errors: [RedisProxySpec::FakeRedis::Error]
    )
    _(proxy.read("k")).must_be_nil
  end

  it "bypasses all errors when configured with :all" do
    redis = RedisProxySpec::FakeRedis.new(raises: RuntimeError.new("anything"))
    proxy = Rack::Attack::StoreProxy::RedisProxy.new(redis, bypassable_store_errors: :all)
    _(proxy.read("k")).must_be_nil
  end

  it "re-raises default errors when configured with :none" do
    redis = RedisProxySpec::FakeRedis.new(raises: Redis::BaseConnectionError.new("down"))
    proxy = Rack::Attack::StoreProxy::RedisProxy.new(redis, bypassable_store_errors: :none)
    _(-> { proxy.read("k") }).must_raise Redis::BaseConnectionError
  end

  it "user-provided Array overrides the default (does not merge)" do
    redis = RedisProxySpec::FakeRedis.new(raises: Redis::BaseConnectionError.new("down"))
    proxy = Rack::Attack::StoreProxy::RedisProxy.new(
      redis,
      bypassable_store_errors: [RedisProxySpec::FakeRedis::Error]
    )
    _(-> { proxy.read("k") }).must_raise Redis::BaseConnectionError
  end

  it "returns nil from #increment on a matching error" do
    redis = RedisProxySpec::FakeRedis.new(raises: Redis::BaseConnectionError.new("down"))
    proxy = Rack::Attack::StoreProxy::RedisProxy.new(redis)
    _(proxy.increment("k", 1, expires_in: 60)).must_be_nil
  end

  it "returns nil from #delete on a matching error" do
    redis = RedisProxySpec::FakeRedis.new(raises: Redis::BaseConnectionError.new("down"))
    proxy = Rack::Attack::StoreProxy::RedisProxy.new(redis)
    _(proxy.delete("k")).must_be_nil
  end

  it "raises MisconfiguredStoreError for invalid config" do
    redis = RedisProxySpec::FakeRedis.new
    _(-> {
      Rack::Attack::StoreProxy::RedisProxy.new(redis, bypassable_store_errors: :sometimes)
    }).must_raise Rack::Attack::MisconfiguredStoreError
  end
end
