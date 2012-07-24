require 'rack'
module Rack
  class Attack
    class << self

      attr_reader :blocks, :throttles, :whitelists

      def block(name, &block)
        (@blocks ||= {})[name] = block
      end

      def throttle
      end

      def whitelist
      end

    end

    def initialize(app)
      @app = app
    end

    def call(env)
      puts 'Rack attack!'
      @app.call(env)
    end

  end
end
