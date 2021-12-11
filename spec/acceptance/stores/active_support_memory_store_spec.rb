# frozen_string_literal: true

require_relative "../../spec_helper"
require_relative "../../support/cache_store_helper"

describe "ActiveSupport::Cache::MemoryStore as a cache backend" do
  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  after do
    Rack::Attack.reset!
  end

  it_works_for_cache_backed_features
end
