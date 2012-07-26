require 'rack'
module Rack::Attack
  require 'rack/attack/cache'

  class << self

    attr_reader :cache, :notifier

    def whitelist(name, &block)
      (@whitelists ||= {})[name] = block
    end

    def block(name, &block)
      (@blocks ||= {})[name] = block
    end

    def throttle
    end

    def whitelists; @whitelists ||= {}; end
    def blocks;     @blocks     ||= {}; end
    def throttles;  @throttles  ||= {}; end

    def new(app)
      @cache = Cache.new
      @notifier = ActiveSupport::Notifications if defined?(ActiveSupport::Notifications)
      @app = app
      self
    end


    def call(env)
      req = Rack::Request.new(env)

      if whitelisted?(req)
        return @app.call(env)
      end

      if blocked?(req)
        blocked_response
      elsif throttled?(req)
      else
        @app.call(env)
      end
    end

    def whitelisted?(req)
      whitelists.any? do |name, block|
        block[req].tap{ |match|
          instrument(:type => :whitelist, :name => name, :request => req) if match
        }
      end
    end

    def blocked?(req)
      blocks.any? do |name, block|
        block[req].tap { |match|
          instrument(:type => :block, :name => name, :request => req) if match
        }
      end
    end

    def throttled?(req)
      false
    end

    def instrument(payload)
      notifier.instrument('rack.attack', payload) if notifier
    end

    def blocked_response
      [503, {}, ['Blocked']]
    end

    def throttled_response
      [503, {}, ['Throttled']]
    end

    def clear!
      @whitelists, @blocks, @throttles = {}, {}, {}
    end

  end
end
