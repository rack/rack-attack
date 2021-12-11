# frozen_string_literal: true

module Rack
  class Attack
    module StoreHandlers
      module ActiveSupportMemCacheStoreHandler
        extend StoreHandlers

        def self.handles?(store)
          store.class.name == "ActiveSupport::Cache::MemCacheStore"
        end

        def self.extract_backend(store)
          store.instance_variable_get(:@data)
        end

        def self.adapter_class
          Adapters::DalliClientAdapter
        end
      end
    end
  end
end
