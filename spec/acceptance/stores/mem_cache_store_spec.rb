require_relative "../../spec_helper"
require_relative "../../support/cache_store_helper"

describe "MemCacheStore as a cache backend" do
  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemCacheStore.new
  end

  after do
    Rack::Attack.cache.store.flush_all
  end

  it_works_for_cache_backed_features
end
