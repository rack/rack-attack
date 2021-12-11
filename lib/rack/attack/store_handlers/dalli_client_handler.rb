# frozen_string_literal: true

module Rack
  class Attack
    module StoreHandlers
      module DalliClientHandler
        extend StoreHandlers

        def self.handles?(store)
          defined?(::Dalli::Client) && instance_of_or_pooled?(store, ::Dalli::Client)
        end

        def self.adapter_class
          Adapters::DalliClientAdapter
        end
      end
    end
  end
end
