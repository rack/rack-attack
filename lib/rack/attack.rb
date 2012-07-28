require 'rack'
module Rack::Attack
  require 'rack/attack/cache'
  require 'rack/attack/throttle'
  require 'rack/attack/whitelist'
  require 'rack/attack/blacklist'

  class << self

    attr_reader :cache, :notifier
    attr_accessor :blacklisted_response, :throttled_response

    def whitelist(name, &block)
      (@whitelists ||= {})[name] = Whitelist.new(name, block)
    end

    def blacklist(name, &block)
      (@blacklists ||= {})[name] = Blacklist.new(name, block)
    end

    def throttle(name, options, &block)
      (@throttles ||= {})[name] = Throttle.new(name, options, block)
    end

    def whitelists; @whitelists ||= {}; end
    def blacklists; @blacklists ||= {}; end
    def throttles;  @throttles  ||= {}; end

    def new(app)
      @cache ||= Cache.new
      @notifier = ActiveSupport::Notifications if defined?(ActiveSupport::Notifications)
      @blacklisted_response = lambda {|env| [503, {}, ['Blocked']] }
      @throttled_response   = lambda {|env|
        retry_after = env['rack.attack.throttled'][:period] rescue nil
        [503, {'Retry-After' => retry_after}, ['Retry later']]
      }

      @app = app
      self
    end


    def call(env)
      req = Rack::Request.new(env)

      if whitelisted?(req)
        return @app.call(env)
      end

      if blacklisted?(req)
        blacklisted_response[env]
      elsif throttled?(req)
        throttled_response[env]
      else
        @app.call(env)
      end
    end

    def whitelisted?(req)
      whitelists.any? do |name, whitelist|
        whitelist[req]
      end
    end

    def blacklisted?(req)
      blacklists.any? do |name, blacklist|
        blacklist[req]
      end
    end

    def throttled?(req)
      throttles.any? do |name, throttle|
        throttle[req]
      end
    end

    def instrument(payload)
      notifier.instrument('rack.attack', payload) if notifier
    end

   def clear!
      @whitelists, @blacklists, @throttles = {}, {}, {}
    end

  end
end
