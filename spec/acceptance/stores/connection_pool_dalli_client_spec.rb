# frozen_string_literal: true

require_relative "../../spec_helper"

if defined?(::Dalli) && defined?(::ConnectionPool)
  require_relative "../../support/cache_store_helper"

  describe "ConnectionPool with Dalli::Client as a cache backend" do
    before do
      Rack::Attack.cache.store = ConnectionPool.new { Dalli::Client.new }
    end

    after do
      Rack::Attack.cache.store.flush_all
    end

    it_works_for_cache_backed_features
  end
end
