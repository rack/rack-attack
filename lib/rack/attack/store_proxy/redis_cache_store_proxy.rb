# frozen_string_literal: true

require 'rack/attack/base_proxy'

module Rack
  class Attack
    module StoreProxy
      class RedisCacheStoreProxy < BaseProxy
        def self.handle?(store)
          store.class.name == "ActiveSupport::Cache::RedisCacheStore"
        end

        if defined?(::ActiveSupport) && ::ActiveSupport::VERSION::MAJOR < 6
          def increment(name, amount = 1, **options)
            # RedisCacheStore#increment ignores options[:expires_in] in versions prior to 6.
            #
            # So in order to workaround this we use RedisCacheStore#write (which sets expiration) to initialize
            # the counter. After that we continue using the original RedisCacheStore#increment.
            if options[:expires_in] && !read(name)
              write(name, amount, options)

              amount
            else
              super
            end
          end
        end

        def read(name, options = {})
          super(name, options.merge!(raw: true))
        end

        def write(name, value, options = {})
          super(name, value, options.merge!(raw: true))
        end

        def delete_matched(matcher, options = nil)
          super(matcher.source, options)
        end
      end
    end
  end
end
