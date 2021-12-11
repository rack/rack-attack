# frozen_string_literal: true

module Rack
  class Attack
    module StoreHandlers
      module ActiveSupportMemoryStoreHandler
        extend StoreHandlers

        def self.handles?(store)
          store.class.name == "ActiveSupport::Cache::MemoryStore"
        end

        def self.adapter_class
          Adapters::ActiveSupportMemoryStoreAdapter
        end
      end
    end
  end
end
