# frozen_string_literal: true

module Rack
  class Attack
    module Adapters
      class Base
        attr_reader :backend

        def initialize(backend)
          @backend = backend
          define_the_with_method
        end

        private

        # Adds support for ConnectionPool backends out of the box, rescuing specified errors per adapter.
        def define_the_with_method
          backend_responds_to_with = backend.respond_to?(:with)

          singleton_class.class_exec do
            if backend_responds_to_with
              def with
                @backend.with { |client| yield client }
              rescue => e
                raise e unless e.is_a?(rescue_from_error)

                0
              end
            else
              def with
                yield @backend
              rescue => e
                raise e unless e.is_a?(rescue_from_error)

                0
              end
            end
          end
        end

        # Define this method on your adapter, returning the error class to be rescued from,
        # if it's using the +with+ method.
        def rescue_from_error
          raise NotImplementedError
        end
      end
    end
  end
end
