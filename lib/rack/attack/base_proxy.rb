# frozen_string_literal: true

require 'delegate'

module Rack
  class Attack
    class BaseProxy < SimpleDelegator
      attr_reader :bypassable_store_errors

      def initialize(store, bypassable_store_errors: nil)
        super(store)
        @bypassable_store_errors = normalize_bypassable_store_errors(bypassable_store_errors)
      end

      def self.default_bypassable_store_errors
        []
      end

      protected

      def handle_store_error
        yield
      rescue => e
        raise e unless should_bypass_error?(e)
      end

      private

      def should_bypass_error?(error)
        case @bypassable_store_errors
        when :all
          true
        when :none
          false
        else
          @bypassable_store_errors.any? { |candidate| error_matches?(error, candidate) }
        end
      end

      def error_matches?(error, candidate)
        case candidate
        when Class
          error.is_a?(candidate)
        when String
          klass = error.class
          while klass
            return true if klass.name == candidate

            klass = klass.superclass
          end
          false
        end
      end

      def normalize_bypassable_store_errors(value)
        case value
        when nil
          self.class.default_bypassable_store_errors
        when :all, :none
          value
        when Array
          unless value.all? { |e| e.is_a?(Class) || e.is_a?(String) }
            raise Rack::Attack::MisconfiguredStoreError,
                  "bypassable_store_errors Array must contain only Class or String entries"
          end
          value
        else
          raise Rack::Attack::MisconfiguredStoreError,
                "bypassable_store_errors must be :all, :none, or an Array of error Classes or class name Strings"
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
