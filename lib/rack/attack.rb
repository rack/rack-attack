# frozen_string_literal: true

require 'rack'
require 'forwardable'
require 'rack/attack/cache'
require 'rack/attack/configuration'
require 'rack/attack/path_normalizer'
require 'rack/attack/request'
require 'rack/attack/store_proxy/dalli_proxy'
require 'rack/attack/store_proxy/mem_cache_store_proxy'
require 'rack/attack/store_proxy/redis_proxy'
require 'rack/attack/store_proxy/redis_store_proxy'
require 'rack/attack/store_proxy/redis_cache_store_proxy'
require 'rack/attack/store_proxy/active_support_redis_store_proxy'

require 'rack/attack/railtie' if defined?(::Rails)

module Rack
  class Attack
    class Error < StandardError; end
    class MisconfiguredStoreError < Error; end
    class MissingStoreError < Error; end
    class IncompatibleStoreError < Error; end

    autoload :Check,                'rack/attack/check'
    autoload :Throttle,             'rack/attack/throttle'
    autoload :Safelist,             'rack/attack/safelist'
    autoload :Blocklist,            'rack/attack/blocklist'
    autoload :Track,                'rack/attack/track'
    autoload :Fail2Ban,             'rack/attack/fail2ban'
    autoload :Allow2Ban,            'rack/attack/allow2ban'

    THREAD_CALLING_KEY = 'rack.attack.calling'
    DEFAULT_FAILURE_COOLDOWN = 60
    DEFAULT_ALLOWED_ERRORS = %w[Dalli::DalliError Redis::BaseError].freeze

    class << self
      attr_accessor :enabled,
                    :notifier,
                    :throttle_discriminator_normalizer,
                    :error_handler,
                    :allowed_errors,
                    :failure_cooldown

      attr_reader :configuration

      def instrument(request)
        if notifier
          event_type = request.env["rack.attack.match_type"]
          notifier.instrument("#{event_type}.rack_attack", request: request)

          # Deprecated: Keeping just for backwards compatibility
          notifier.instrument("rack.attack", request: request)
        end
      end

      def cache
        @cache ||= Cache.new
      end

      def clear!
        warn "[DEPRECATION] Rack::Attack.clear! is deprecated. Please use Rack::Attack.clear_configuration instead"
        @configuration.clear_configuration
      end

      def reset!
        cache.reset!
      end

      def failed!
        @last_failure_at = Time.now
      end

      def failure_cooldown?
        return false unless @last_failure_at && failure_cooldown

        Time.now < @last_failure_at + failure_cooldown
      end

      def allow_error?(error)
        allowed_errors&.any? do |ignored_error|
          case ignored_error
          when String then error.class.ancestors.any? {|a| a.name == ignored_error }
          else error.is_a?(ignored_error)
          end
        end
      end

      def calling?
        !!thread_store[THREAD_CALLING_KEY]
      end

      def with_calling
        thread_store[THREAD_CALLING_KEY] = true
        yield
      ensure
        thread_store[THREAD_CALLING_KEY] = nil
      end

      def thread_store
        defined?(RequestStore) ? RequestStore.store : Thread.current
      end

      extend Forwardable
      def_delegators(
        :@configuration,
        :safelist,
        :blocklist,
        :blocklist_ip,
        :safelist_ip,
        :throttle,
        :track,
        :throttled_responder,
        :throttled_responder=,
        :blocklisted_responder,
        :blocklisted_responder=,
        :blocklisted_response,
        :blocklisted_response=,
        :throttled_response,
        :throttled_response=,
        :throttled_response_retry_after_header,
        :throttled_response_retry_after_header=,
        :clear_configuration,
        :safelists,
        :blocklists,
        :throttles,
        :tracks
      )
    end

    # Set class defaults
    self.failure_cooldown = DEFAULT_FAILURE_COOLDOWN
    self.allowed_errors = DEFAULT_ALLOWED_ERRORS.dup

    # Set instance defaults
    @enabled = true
    @notifier = ActiveSupport::Notifications if defined?(ActiveSupport::Notifications)
    @throttle_discriminator_normalizer = lambda do |discriminator|
      discriminator.to_s.strip.downcase
    end
    @configuration = Configuration.new

    attr_reader :configuration

    def initialize(app)
      @app = app
      @configuration = self.class.configuration
    end

    def call(env)
      return @app.call(env) if !self.class.enabled || env["rack.attack.called"] || self.class.failure_cooldown?

      env["rack.attack.called"] = true
      env['PATH_INFO'] = PathNormalizer.normalize_path(env['PATH_INFO'])
      request = Rack::Attack::Request.new(env)
      result = :allow

      self.class.with_calling do
        begin
          result = get_result(request)
        rescue StandardError => error
          return do_error_response(error, request)
        end
      end

      do_response(result, request)
    end

    private

    def get_result(request)
      if configuration.safelisted?(request)
        :allow
      elsif configuration.blocklisted?(request)
        :block
      elsif configuration.throttled?(request)
        :throttle
      else
        configuration.tracked?(request)
        :allow
      end
    end

    def do_response(result, request)
      case result
      when :block then do_block_response(request)
      when :throttle then do_throttle_response(request)
      else @app.call(request.env)
      end
    end

    def do_block_response(request)
      # Deprecated: Keeping blocklisted_response for backwards compatibility
      if configuration.blocklisted_response
        configuration.blocklisted_response.call(request.env)
      else
        configuration.blocklisted_responder.call(request)
      end
    end

    def do_throttle_response(request)
      # Deprecated: Keeping throttled_response for backwards compatibility
      if configuration.throttled_response
        configuration.throttled_response.call(request.env)
      else
        configuration.throttled_responder.call(request)
      end
    end

    def do_error_response(error, request)
      self.class.failed!
      result = error_result(error, request)
      result ? do_response(result, request) : raise(error)
    end

    def error_result(error, request)
      handler = self.class.error_handler
      if handler
        error_handler_result(handler, error, request)
      elsif self.class.allow_error?(error)
        :allow
      end
    end

    def error_handler_result(handler, error, request)
      result = handler

      if handler.is_a?(Proc)
        args = [error, request].first(handler.arity)
        result = handler.call(*args) # may raise error
      end

      %i[block throttle].include?(result) ? result : :allow
    end
  end
end
