# frozen_string_literal: true

require "rack/attack/base_proxy"

module Rack
  class Attack
    module StoreProxy
      class SQLiteProxy < BaseProxy
        def self.handle?(store)
          defined?(::SQLite3) && store.is_a?(::SQLite3::Database)
        end

        def initialize(store)
          super
          create_table
        end

        def read(key)
          rescuing do
            value = get_first_value(
              "SELECT value FROM rack_attack_cache WHERE key = ? AND (expires_at IS NULL OR expires_at > ?)",
              [key, Time.now.to_i]
            )
            value&.to_i
          end
        end

        def write(key, value, options = {})
          rescuing do
            expires_at = options[:expires_in] ? Time.now.to_i + options[:expires_in] : nil
            execute(
              "INSERT OR REPLACE INTO rack_attack_cache (key, value, expires_at) VALUES (?, ?, ?)",
              [key, value.to_s, expires_at]
            )
            value
          end
        end

        def increment(key, amount, options = {})
          rescuing do
            transaction do
              current = read(key) || 0
              new_value = current + amount
              write(key, new_value, options)
              new_value
            end
          end
        end

        def delete(key, _options = {})
          rescuing do
            execute("DELETE FROM rack_attack_cache WHERE key = ?", [key])
            true
          end
        end

        def delete_matched(matcher, _options = nil)
          rescuing do
            execute("DELETE FROM rack_attack_cache WHERE key LIKE ?", [matcher.source])
            true
          end
        end

        private

        def rescuing
          cleanup_expired
          yield
        rescue SQLite3::Exception => e
          warn "SQLiteProxy error: #{e.message}"
          nil
        end

        def cleanup_expired
          execute(
            "DELETE FROM rack_attack_cache WHERE expires_at IS NOT NULL AND expires_at <= ?",
            [Time.now.to_i]
          )
        end

        def create_table
          execute <<-SQL
            CREATE TABLE IF NOT EXISTS rack_attack_cache (
              key TEXT PRIMARY KEY,
              value TEXT,
              expires_at INTEGER
            )
          SQL

          execute <<-SQL
            CREATE INDEX IF NOT EXISTS idx_rack_attack_expires
            ON rack_attack_cache(expires_at)
          SQL
        end
      end
    end
  end
end
