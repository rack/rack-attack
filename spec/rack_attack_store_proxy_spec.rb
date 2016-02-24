require_relative 'spec_helper'
require 'active_support/cache/dalli_store'
require 'active_support/cache/mem_cache_store'
require 'active_support/cache/redis_store'
require 'connection_pool'

describe Rack::Attack::StoreProxy do
  describe '.build' do
    it 'ActiveSupport::Cache::MemoryStore' do
      store = Rack::Attack::StoreProxy.build(ActiveSupport::Cache::MemoryStore.new)
      store.class.must_equal ActiveSupport::Cache::MemoryStore
    end

    it 'ActiveSupport::Cache::DalliStore' do
      store = Rack::Attack::StoreProxy.build(ActiveSupport::Cache::DalliStore.new)
      store.class.must_equal ActiveSupport::Cache::DalliStore
    end

    it 'ActiveSupport::Cache::RedisStore' do
      store = Rack::Attack::StoreProxy.build(ActiveSupport::Cache::RedisStore.new)
      store.class.must_equal Rack::Attack::StoreProxy::RedisStoreProxy
    end

    it 'ActiveSupport::Cache::RedisStore with connection pool' do
      store = Rack::Attack::StoreProxy.build(ActiveSupport::Cache::RedisStore.new(pool_size: 2))
      store.class.must_equal Rack::Attack::StoreProxy::RedisStoreProxy
    end

    it 'ActiveSupport::Cache::MemCacheStore' do
      store = Rack::Attack::StoreProxy.build(ActiveSupport::Cache::MemCacheStore.new)
      store.class.must_equal Rack::Attack::StoreProxy::DalliProxy
    end

    it 'Dalli::Client' do
      store = Rack::Attack::StoreProxy.build(Dalli::Client.new)
      store.class.must_equal Rack::Attack::StoreProxy::DalliProxy
    end

    it 'Dalli::Client with connection pool' do
      store = Rack::Attack::StoreProxy.build(ConnectionPool.new { Dalli::Client.new })
      store.class.must_equal Rack::Attack::StoreProxy::DalliProxy
    end

    it 'Redis::Store' do
      store = Rack::Attack::StoreProxy.build(Redis::Store.new)
      store.class.must_equal Rack::Attack::StoreProxy::RedisStoreProxy
    end

    it 'Redis::Store with connection pool' do
      store = Rack::Attack::StoreProxy.build(ConnectionPool.new { Redis::Store.new })
      store.class.must_equal Rack::Attack::StoreProxy::RedisStoreProxy
    end
  end
end
