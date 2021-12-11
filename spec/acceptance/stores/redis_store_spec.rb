# frozen_string_literal: true

require_relative "../../spec_helper"

if defined?(::Redis::Store)
  require_relative "../../support/cache_store_helper"

  describe "Redis::Store as a cache backend" do
    before do
      Rack::Attack.cache.store = ::Redis::Store.new
    end

    after do
      Rack::Attack.reset!
    end

    it_works_for_cache_backed_features
  end
end
