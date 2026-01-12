# frozen_string_literal: true

require 'delegate'

module Rack
  class Attack
    class BaseProxy < SimpleDelegator
      attr_reader :bypass_all_store_errors, :bypassable_store_errors

      def initialize(store, bypass_all_store_errors: false, bypassable_store_errors: [])
        super(store)
        @bypass_all_store_errors = bypass_all_store_errors
        @bypassable_store_errors = bypassable_store_errors
      end

      protected

      def handle_store_error(&block)
        yield
      rescue => error
        if should_bypass_error?(error)
          nil
        else
          raise error
        end
      end

      private

      def should_bypass_error?(error)
        return true if @bypass_all_store_errors
        
        @bypassable_store_errors.any? do |bypassable_error|
          case bypassable_error
          when Class
            error.is_a?(bypassable_error)
          when String
            error.class.name == bypassable_error
          else
            false
          end
        end
      end

      class << self
        def proxies
          @@proxies ||= []
        end

        def inherited(klass)
          super
          proxies << klass
        end

        def lookup(store)
          proxies.find { |proxy| proxy.handle?(store) }
        end

        def handle?(_store)
          raise NotImplementedError
        end
      end
    end
  end
end
