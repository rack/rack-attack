# frozen_string_literal: true

require_relative "../../spec_helper"

if defined?(::SQLite3)
  require_relative "../../support/cache_store_helper"

  describe "SQLite as a cache backend" do
    before do
      # Use in-memory SQLite database for testing
      db = SQLite3::Database.new(":memory:")
      Rack::Attack.cache.store = db
    end

    after do
      # Clean up the database
      Rack::Attack.cache.store.execute("DROP TABLE IF EXISTS rack_attack_cache")
    end

    it_works_for_cache_backed_features(
      fetch_from_store: ->(key) {
        value = Rack::Attack.cache.store.get_first_value(
          "SELECT value FROM rack_attack_cache WHERE key = ?", [key]
        )
        value&.to_i
      }
    )
  end
end
