require_relative '../spec_helper'

describe Rack::Attack::Cache do
  def delete(key)
    if @cache.store.respond_to?(:delete)
      @cache.store.delete(key)
    else
      @cache.store.del(key)
    end
  end

  def sleep_until_expired
    sleep(@expires_in * 1.1) # Add 10% to reduce errors
  end

  require 'active_support/cache/dalli_store'
  require 'active_support/cache/redis_store'
  cache_stores = [
    ActiveSupport::Cache::MemoryStore.new,
    ActiveSupport::Cache::DalliStore.new("localhost"),
    ActiveSupport::Cache::RedisStore.new("localhost"),
    Redis::Store.new
  ]

  cache_stores.each do |store|
    store = Rack::Attack::StoreProxy.build(store)
    describe "with #{store.class}" do

      before {
        @cache ||= Rack::Attack::Cache.new
        @key = "rack::attack:cache-test-key"
        @expires_in = 1
        @cache.store = store
        delete(@key)
      }

      after { delete(@key) }

      describe "do_count once" do
        it "should be 1" do
          @cache.send(:do_count, @key, @expires_in).must_equal 1
        end
      end

      describe "do_count twice" do
        it "must be 2" do
          @cache.send(:do_count, @key, @expires_in)
          @cache.send(:do_count, @key, @expires_in).must_equal 2
        end
      end
      describe "do_count after expires_in" do
        it "must be 1" do
          @cache.send(:do_count, @key, @expires_in)
          sleep_until_expired
          @cache.send(:do_count, @key, @expires_in).must_equal 1
        end
      end

      describe "write" do
        it "should write a value to the store with prefix" do
          @cache.write("cache-test-key", "foobar", 1)
          store.read(@key).must_equal "foobar"
        end
      end

      describe "write after expiry" do
        it "must not have a value" do
          @cache.write("cache-test-key", "foobar", @expires_in)
          sleep_until_expired
          store.read(@key).must_be :nil?
        end
      end

      describe "read" do
        it "must read the value with a prefix" do
          store.write(@key, "foobar", :expires_in => @expires_in)
          @cache.read("cache-test-key").must_equal "foobar"
        end
      end
    end

  end

  describe "should not error if redis is not running" do
    before {
      @cache = Rack::Attack::Cache.new
      @key = "rack::attack:cache-test-key"
      @expires_in = 1
      # Use presumably unused port for Redis client
      @cache.store = ActiveSupport::Cache::RedisStore.new(:host => '127.0.0.1', :port => 3333)
    }
    describe "write" do
      it "should not raise exception" do
        @cache.write("cache-test-key", "foobar", 1)
      end
    end

    describe "read" do
      it "should not raise exception" do
        @cache.read("cache-test-key")
      end
    end

    describe "do_count" do
      it "should not raise exception" do
        @cache.send(:do_count, @key, @expires_in)
      end
    end
  end

end
