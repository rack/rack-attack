# frozen_string_literal: true

require_relative 'spec_helper'

describe "Store proxy defaults (String-based)" do
  it "RedisStoreProxy inherits Redis default bypass list from RedisProxy" do
    skip 'redis gem not available' unless defined?(::Redis)
    _(Rack::Attack::StoreProxy::RedisStoreProxy.default_bypassable_store_errors)
      .must_equal ['Redis::BaseConnectionError']
  end

  it "RedisCacheStoreProxy has no default bypass list (preserves upstream behavior)" do
    _(Rack::Attack::StoreProxy::RedisCacheStoreProxy.default_bypassable_store_errors).must_equal []
  end

  it "MemCacheStoreProxy has no default bypass list (preserves upstream behavior)" do
    _(Rack::Attack::StoreProxy::MemCacheStoreProxy.default_bypassable_store_errors).must_equal []
  end

  it "BaseProxy base default is an empty Array" do
    _(Rack::Attack::BaseProxy.default_bypassable_store_errors).must_equal []
  end

  it "default list entries are Strings so missing gems don't break loading" do
    [
      Rack::Attack::StoreProxy::DalliProxy,
      Rack::Attack::StoreProxy::RedisProxy
    ].each do |proxy_class|
      defaults = proxy_class.default_bypassable_store_errors
      _(defaults.all? { |e| e.is_a?(String) }).must_equal(
        true,
        "#{proxy_class}: expected all defaults to be Strings, got #{defaults.inspect}"
      )
    end
  end
end
