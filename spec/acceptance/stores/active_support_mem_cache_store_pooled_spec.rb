# frozen_string_literal: true

require_relative "../../spec_helper"

if defined?(::ConnectionPool) && defined?(::Dalli)
  require_relative "../../support/cache_store_helper"

  describe "ActiveSupport::Cache::MemCacheStore (pooled) as a cache backend" do
    before do
      Rack::Attack.cache.store = ActiveSupport::Cache::MemCacheStore.new(pool_size: 2)
    end

    after do
      Rack::Attack.cache.store.flush_all
    end

    it_works_for_cache_backed_features
  end
end
