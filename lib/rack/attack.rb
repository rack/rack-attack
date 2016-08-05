require 'rack'
require 'forwardable'

class Rack::Attack
  autoload :Cache,            'rack/attack/cache'
  autoload :PathNormalizer,   'rack/attack/path_normalizer'
  autoload :Check,            'rack/attack/check'
  autoload :Throttle,         'rack/attack/throttle'
  autoload :Safelist,         'rack/attack/safelist'
  autoload :Blocklist,        'rack/attack/blocklist'
  autoload :Track,            'rack/attack/track'
  autoload :StoreProxy,       'rack/attack/store_proxy'
  autoload :DalliProxy,       'rack/attack/store_proxy/dalli_proxy'
  autoload :MemCacheProxy,    'rack/attack/store_proxy/mem_cache_proxy'
  autoload :RedisStoreProxy,  'rack/attack/store_proxy/redis_store_proxy'
  autoload :Fail2Ban,         'rack/attack/fail2ban'
  autoload :Allow2Ban,        'rack/attack/allow2ban'
  autoload :Request,          'rack/attack/request'
  autoload :ResponseRegistry, 'rack/attack/response_registry'

  MATCHED = 'rack.attack.matched'
  MATCH_TYPE = 'rack.attack.match_type'
  MATCH_DISCRIMINATOR = 'rack.attack.match_discriminator'
  MATCH_DATA = 'rack.attack.match_data'

  class << self
    extend Forwardable
    def_delegator :@blocklisted_response_registry, :default=, :blocklisted_response=
    def_delegator :@blocklisted_response_registry, :[], :blocklisted_response
    def_delegator :@blocklisted_response_registry, :[]=, :set_named_blocklisted_response

    def_delegator :@throttled_response_registry, :default=, :throttled_response=
    def_delegator :@throttled_response_registry, :[], :throttled_response

    attr_accessor :notifier

    def safelist(name, &block)
      self.safelists[name] = Safelist.new(name, block)
    end

    def whitelist(name, &block)
      warn "[DEPRECATION] 'Rack::Attack.whitelist' is deprecated.  Please use 'safelist' instead."
      safelist(name, &block)
    end

    def blocklist(name, &block)
      self.blocklists[name] = Blocklist.new(name, block)
    end

    def blacklist(name, &block)
      warn "[DEPRECATION] 'Rack::Attack.blacklist' is deprecated.  Please use 'blocklist' instead."
      blocklist(name, &block)
    end

    def throttle(name, options, &block)
      self.throttles[name] = Throttle.new(name, options, block)
    end

    def track(name, options = {}, &block)
      self.tracks[name] = Track.new(name, options, block)
    end

    def safelists; @safelists ||= {}; end
    def blocklists; @blocklists ||= {}; end
    def throttles;  @throttles  ||= {}; end
    def tracks;     @tracks     ||= {}; end

    def whitelists
      warn "[DEPRECATION] 'Rack::Attack.whitelists' is deprecated.  Please use 'safelists' instead."
      safelists
    end

    def blacklists
      warn "[DEPRECATION] 'Rack::Attack.blacklists' is deprecated.  Please use 'blocklists' instead."
      blocklists
    end

    def safelisted?(req)
      safelists.any? do |name, safelist|
        safelist[req]
      end
    end

    def whitelisted?
      warn "[DEPRECATION] 'Rack::Attack.whitelisted?' is deprecated.  Please use 'safelisted?' instead."
      safelisted?
    end

    def blocklisted?(req)
      blocklists.any? do |name, blocklist|
        blocklist[req]
      end
    end

    def blacklisted?
      warn "[DEPRECATION] 'Rack::Attack.blacklisted?' is deprecated.  Please use 'blocklisted?' instead."
      blocklisted?
    end

    def throttled?(req)
      throttles.any? do |name, throttle|
        throttle[req]
      end
    end

    def tracked?(req)
      tracks.each_value do |tracker|
        tracker[req]
      end
    end

    def instrument(req)
      notifier.instrument('rack.attack', req) if notifier
    end

    def cache
      @cache ||= Cache.new
    end

    def clear!
      @safelists, @blocklists, @throttles, @tracks = {}, {}, {}, {}
      @blocklisted_response_registry = ResponseRegistry.new(default: @default_blocklisted_response)
      @throttled_response_registry = ResponseRegistry.new(default: @default_throttled_response)
    end

    def blacklisted_response=(res)
      warn "[DEPRECATION] 'Rack::Attack.blacklisted_response=' is deprecated.  Please use 'blocklisted_response=' instead."
      self.blocklisted_response=(res)
    end

    def blacklisted_response
      warn "[DEPRECATION] 'Rack::Attack.blacklisted_response' is deprecated.  Please use 'blocklisted_response' instead."
      self.blocklisted_response
    end

  end

  # Set defaults
  @notifier             = ActiveSupport::Notifications if defined?(ActiveSupport::Notifications)
  @default_blocklisted_response = lambda {|env| [403, {'Content-Type' => 'text/plain'}, ["Forbidden\n"]] }
  @blocklisted_response_registry = ResponseRegistry.new(default: @default_blocklisted_response)

  @default_throttled_response = lambda {|env|
    retry_after = (env[MATCH_DATA] || {})[:period]
    [429, {'Content-Type' => 'text/plain', 'Retry-After' => retry_after.to_s}, ["Retry later\n"]]
  }
  @throttled_response_registry = ResponseRegistry.new(default: @default_throttled_response)

  def initialize(app)
    @app = app
  end

  def call(env)
    env['PATH_INFO'] = PathNormalizer.normalize_path(env['PATH_INFO'])
    req = Rack::Attack::Request.new(env)

    if safelisted?(req)
      @app.call(env)
    elsif blocklisted?(req)
      self.class.blocklisted_response(env[MATCHED]).call(env)
    elsif throttled?(req)
      self.class.throttled_response(env[MATCHED]).call(env)
    else
      tracked?(req)
      @app.call(env)
    end
  end

  extend Forwardable
  def_delegators self, :safelisted?,
                       :blocklisted?,
                       :throttled?,
                       :tracked?
end
