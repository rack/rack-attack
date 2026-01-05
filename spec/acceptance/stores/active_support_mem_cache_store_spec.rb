# frozen_string_literal: true

require_relative "../../spec_helper"

if defined?(::Dalli) && defined?(::ActiveSupport::Cache::MemCacheStore)
  require_relative "../../support/cache_store_helper"

  describe "ActiveSupport::Cache::MemCacheStore as a cache backend" do
    before do
      Rack::Attack.cache.store = if ActiveSupport.gem_version >= Gem::Version.new("7.2.0")
                                   ActiveSupport::Cache::MemCacheStore.new(pool: true)
                                 else
                                   ActiveSupport::Cache::MemCacheStore.new(pool_size: 2)
                                 end
    end

    after do
      Rack::Attack.cache.store.clear
    end

    it_works_for_cache_backed_features(fetch_from_store: ->(key) { Rack::Attack.cache.store.read(key) })
  end
end
