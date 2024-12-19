# frozen_string_literal: true

require_relative "spec_helper"

describe "Rack::Attack.reset!" do
  it "raises an error when is not supported by cache store" do
    Rack::Attack.cache.store = Class.new
    assert_raises(Rack::Attack::IncompatibleStoreError) do
      Rack::Attack.reset!
    end
  end

  if defined?(Redis)
    it "should delete rack attack keys" do
      redis = Redis.new
      redis.set("key", "value")
      redis.set("#{Rack::Attack.cache.prefix}::key", "value")
      Rack::Attack.cache.store = redis
      Rack::Attack.reset!

      _(redis.get("key")).must_equal "value"
      _(redis.get("#{Rack::Attack.cache.prefix}::key")).must_be_nil
    end
  end

  if defined?(Redis::Store)
    it "should delete rack attack keys" do
      redis_store = Redis::Store.new
      redis_store.set("key", "value")
      redis_store.set("#{Rack::Attack.cache.prefix}::key", "value")
      Rack::Attack.cache.store = redis_store
      Rack::Attack.reset!

      _(redis_store.get("key")).must_equal "value"
      _(redis_store.get("#{Rack::Attack.cache.prefix}::key")).must_be_nil
    end
  end

  if defined?(Redis) && defined?(ActiveSupport::Cache::RedisCacheStore)
    it "should delete rack attack keys" do
      redis_cache_store = ActiveSupport::Cache::RedisCacheStore.new
      redis_cache_store.write("key", "value")
      redis_cache_store.write("#{Rack::Attack.cache.prefix}::key", "value")
      Rack::Attack.cache.store = redis_cache_store
      Rack::Attack.reset!

      _(redis_cache_store.read("key")).must_equal "value"
      _(redis_cache_store.read("#{Rack::Attack.cache.prefix}::key")).must_be_nil
    end

    describe "with a namespaced cache" do
      it "should delete rack attack keys" do
        redis_cache_store = ActiveSupport::Cache::RedisCacheStore.new(namespace: "ns")
        redis_cache_store.write("key", "value")
        redis_cache_store.write("#{Rack::Attack.cache.prefix}::key", "value")
        Rack::Attack.cache.store = redis_cache_store
        Rack::Attack.reset!

        _(redis_cache_store.read("key")).must_equal "value"
        _(redis_cache_store.read("#{Rack::Attack.cache.prefix}::key")).must_be_nil
      end
    end
  end

  if defined?(ActiveSupport::Cache::MemoryStore)
    it "should delete rack attack keys" do
      memory_store = ActiveSupport::Cache::MemoryStore.new
      memory_store.write("key", "value")
      memory_store.write("#{Rack::Attack.cache.prefix}::key", "value")
      Rack::Attack.cache.store = memory_store
      Rack::Attack.reset!

      _(memory_store.read("key")).must_equal "value"
      _(memory_store.read("#{Rack::Attack.cache.prefix}::key")).must_be_nil
    end

    describe "with a namespaced cache" do
      it "should delete rack attack keys" do
        memory_store = ActiveSupport::Cache::MemoryStore.new(namespace: "ns")
        memory_store.write("key", "value")
        memory_store.write("#{Rack::Attack.cache.prefix}::key", "value")
        Rack::Attack.cache.store = memory_store
        Rack::Attack.reset!

        _(memory_store.read("key")).must_equal "value"
        _(memory_store.read("#{Rack::Attack.cache.prefix}::key")).must_be_nil
      end
    end
  end
end
