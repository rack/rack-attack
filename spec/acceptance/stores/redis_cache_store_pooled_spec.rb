require_relative "../../spec_helper"
require_relative "../../support/cache_store_helper"

require "timecop"

if ActiveSupport.version >= Gem::Version.new("5.2.0")
  describe "RedisCacheStore (pooled) as a cache backend" do
    before do
      Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(pool_size: 2)
    end

    after do
      Rack::Attack.cache.store.clear
    end

    it_works_for_cache_backed_features

    it "doesn't leak keys" do
      Rack::Attack.throttle("by ip", limit: 1, period: 1) do |request|
        request.ip
      end

      key = nil

      # Freeze time during these statement to be sure that the key used by rack attack is the same
      # we pre-calculate in local variable `key`
      Timecop.freeze do
        key = "rack::attack:#{Time.now.to_i}:by ip:1.2.3.4"

        get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
      end

      assert Rack::Attack.cache.store.fetch(key)

      sleep 2.1

      assert_nil Rack::Attack.cache.store.fetch(key)
    end
  end
end
