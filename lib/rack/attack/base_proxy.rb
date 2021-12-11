# frozen_string_literal: true

require 'delegate'

module Rack
  class Attack
    class BaseProxy < SimpleDelegator
      class << self
        def proxies
          @@proxies ||= []
        end

        def inherited(klass)
          proxies << klass
        end

        def lookup(store)
          proxies.find { |proxy| proxy.handle?(store) }
        end

        def handle?(_store)
          raise NotImplementedError
        end

        def build(store)
          new(store)
        end
      end

      def initialize(_store)
        super
        stub_with_if_missing
      end

      private

      def stub_with_if_missing
        return if __getobj__.respond_to?(:with)

        class << self
          def with
            yield __getobj__
          end
        end
      end
    end
  end
end
