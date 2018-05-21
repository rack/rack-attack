require_relative "../../spec_helper"
require_relative "../../support/cache_store_helper"

if ActiveSupport.version >= Gem::Version.new("5.2.0")
  describe "RedisCacheStore as a cache backend" do
    before do
      Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new
    end

    after do
      Rack::Attack.cache.store.clear
    end

    it_works_for_cache_backed_features
  end
end
