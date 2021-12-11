# frozen_string_literal: true

require 'rack/attack/adapters/base'

module Rack
  class Attack
    module Adapters
      class DalliClientAdapter < Base
        def read(key)
          with { |dc| dc.get(key) }
        end

        def write(key, value, options = {})
          with { |dc| dc.set(key, value, options.fetch(:expires_in, 0), raw: true) }
        end

        def increment(key, amount, options = {})
          with { |dc| dc.incr(key, amount, options.fetch(:expires_in, 0), amount) }
        end

        def delete(key)
          with { |dc| dc.delete(key) }
        end

        def flush_all
          with { |dc| dc.flush_all }
        end

        private

        def rescue_from_error
          ::Dalli::DalliError
        end
      end
    end
  end
end
