require 'rack'
require 'forwardable'
require 'rack/attack/path_normalizer'
require 'rack/attack/request'
require "ipaddr"

class Rack::Attack
  class MisconfiguredStoreError < StandardError; end
  class MissingStoreError < StandardError; end

  autoload :Cache,                'rack/attack/cache'
  autoload :Check,                'rack/attack/check'
  autoload :Throttle,             'rack/attack/throttle'
  autoload :Safelist,             'rack/attack/safelist'
  autoload :Blocklist,            'rack/attack/blocklist'
  autoload :Track,                'rack/attack/track'
  autoload :StoreProxy,           'rack/attack/store_proxy'
  autoload :DalliProxy,           'rack/attack/store_proxy/dalli_proxy'
  autoload :MemCacheProxy,        'rack/attack/store_proxy/mem_cache_proxy'
  autoload :RedisStoreProxy,      'rack/attack/store_proxy/redis_store_proxy'
  autoload :RedisCacheStoreProxy, 'rack/attack/store_proxy/redis_cache_store_proxy'
  autoload :Fail2Ban,             'rack/attack/fail2ban'
  autoload :Allow2Ban,            'rack/attack/allow2ban'

  class << self
    attr_accessor :notifier, :blocklisted_response, :throttled_response

    def safelist(name, &block)
      self.safelists[name] = Safelist.new(name, block)
    end

    def blocklist(name, &block)
      self.blocklists[name] = Blocklist.new(name, block)
    end

    def blocklist_ip(ip_address)
      @ip_blocklists ||= []
      ip_blocklist_proc = lambda { |request| IPAddr.new(ip_address).include?(IPAddr.new(request.ip)) }
      @ip_blocklists << Blocklist.new(nil, ip_blocklist_proc)
    end

    def safelist_ip(ip_address)
      @ip_safelists ||= []
      ip_safelist_proc = lambda { |request| IPAddr.new(ip_address).include?(IPAddr.new(request.ip)) }
      @ip_safelists << Safelist.new(nil, ip_safelist_proc)
    end

    def throttle(name, options, &block)
      self.throttles[name] = Throttle.new(name, options, block)
    end

    def track(name, options = {}, &block)
      self.tracks[name] = Track.new(name, options, block)
    end

    def safelists;  @safelists  ||= {}; end

    def blocklists; @blocklists ||= {}; end

    def throttles;  @throttles  ||= {}; end

    def tracks;     @tracks     ||= {}; end

    def safelisted?(request)
      ip_safelists.any? { |safelist| safelist.matched_by?(request) } ||
        safelists.any? { |_name, safelist| safelist.matched_by?(request) }
    end

    def blocklisted?(request)
      ip_blocklists.any? { |blocklist| blocklist.matched_by?(request) } ||
        blocklists.any? { |_name, blocklist| blocklist.matched_by?(request) }
    end

    def throttled?(request)
      throttles.any? do |_name, throttle|
        throttle.matched_by?(request)
      end
    end

    def tracked?(request)
      tracks.each_value do |track|
        track.matched_by?(request)
      end
    end

    def instrument(request)
      notifier.instrument('rack.attack', request: request) if notifier
    end

    def cache
      @cache ||= Cache.new
    end

    def clear_configuration
      @safelists, @blocklists, @throttles, @tracks = {}, {}, {}, {}
      @ip_blocklists = []
      @ip_safelists = []
    end

    def clear!
      warn "[DEPRECATION] Rack::Attack.clear! is deprecated. Please use Rack::Attack.clear_configuration instead"
      clear_configuration
    end

    private

    def ip_blocklists
      @ip_blocklists ||= []
    end

    def ip_safelists
      @ip_safelists ||= []
    end
  end

  # Set defaults
  @notifier             = ActiveSupport::Notifications if defined?(ActiveSupport::Notifications)
  @blocklisted_response = lambda { |_env| [403, { 'Content-Type' => 'text/plain' }, ["Forbidden\n"]] }
  @throttled_response   = lambda { |env|
    retry_after = (env['rack.attack.match_data'] || {})[:period]
    [429, { 'Content-Type' => 'text/plain', 'Retry-After' => retry_after.to_s }, ["Retry later\n"]]
  }

  def initialize(app)
    @app = app
  end

  def call(env)
    env['PATH_INFO'] = PathNormalizer.normalize_path(env['PATH_INFO'])
    request = Rack::Attack::Request.new(env)

    if safelisted?(request)
      @app.call(env)
    elsif blocklisted?(request)
      self.class.blocklisted_response.call(env)
    elsif throttled?(request)
      self.class.throttled_response.call(env)
    else
      tracked?(request)
      @app.call(env)
    end
  end

  extend Forwardable
  def_delegators self, :safelisted?, :blocklisted?, :throttled?, :tracked?
end
