# Rack::Attack!!!
*A DSL for blocking & throttling abusive clients*

Rack::Attack is a rack middleware to protect your web app from bad clients.
It allows *whitelisting*, *blacklisting*, *throttling*, and *tracking* based on arbitrary properties of the request.

Throttle state is stored in a configurable cache (e.g. `Rails.cache`), presumably backed by memcached or redis.

## Installation

Install the [rack-attack](http://rubygems.org/gems/rack-attack) gem; or add it to you Gemfile with bundler:

    # In your Gemfile
    gem 'rack-attack'

Tell your app to use the Rack::Attack middleware.
For Rails 3 apps:

    # In config/application.rb
    config.middleware.use Rack::Attack

Or for Rackup files:

    # In config.ru
    use Rack::Attack

Optionally configure the cache store for throttling:

    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new # defaults to Rails.cache

Note that `Rack::Attack.cache` is only used for throttling; not blacklisting & whitelisting. Your cache store must implement `increment` and `write` like [ActiveSupport::Cache::Store](http://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html).

## How it works

The Rack::Attack middleware compares each request against *whitelists*, *blacklists*, *throttles*, and *tracks* that you define. There are none by default.

 * If the request matches any **whitelist**, it is allowed.
 * Otherwise, if the request matches any **blacklist**, it is blocked.
 * Otherwise, if the request matches any **throttle**, a counter is incremented in the Rack::Attack.cache. If the throttle limit is exceeded, the request is blocked.
 * Otherwise, all **tracks** are checked, and the request is allowed.

The algorithm is actually more concise in code: See [Rack::Attack.call](https://github.com/kickstarter/rack-attack/blob/master/lib/rack/attack.rb):

    def call(env)
      req = Rack::Request.new(env)

      if whitelisted?(req)
        @app.call(env)
      elsif blacklisted?(req)
        blacklisted_response[env]
      elsif throttled?(req)
        throttled_response[env]
      else
        tracked?(req)
        @app.call(env)
      end
    end

## About Tracks

`Rack::Attack.track` doesn't affect request processing. Tracks are an easy way to log and measure requests matching arbitrary attributes.

## Usage

Define whitelists, blacklists, throttles, and tracks as blocks that return truthy values if matched, falsy otherwise. In a Rails app 
these go in an initializer in `config/initializers/`.
A [Rack::Request](http://rack.rubyforge.org/doc/classes/Rack/Request.html) object is passed to the block (named 'req' in the examples).

### Whitelists

    # Always allow requests from localhost
    # (blacklist & throttles are skipped)
    Rack::Attack.whitelist('allow from localhost') do |req|
      # Requests are allowed if the return value is truthy
      '127.0.0.1' == req.ip
    end

### Blacklists

    # Block requests from 1.2.3.4
    Rack::Attack.blacklist('block 1.2.3.4') do |req|
      # Request are blocked if the return value is truthy
      '1.2.3.4' == req.ip
    end

    # Block logins from a bad user agent
    Rack::Attack.blacklist('block bad UA logins') do |req|
      req.path == '/login' && req.post? && req.user_agent == 'BadUA'
    end

`Rack::Attack::Fail2Ban` can be combined with blacklists to block all requests from misbehaving clients.
This pattern is inspired by [fail2ban](http://www.fail2ban.org/wiki/index.php/Main_Page).
See the [fail2ban documentation](http://www.fail2ban.org/wiki/index.php/MANUAL_0_8#Jail_Options) for more details on
how the parameters work.

    # Block requests from IP addresses that misbehave.
    # Allow up to 3 bad requests within 10 minutes, then ban the IP for 5 minutes if exceeded
    Rack::Attack.blacklist('fail2ban pentesters') do |req|
      # `filter` returns truthy value if request fails, or if it's from a previously banned IP
      # this causes `blacklist` to block the request
      Rack::Attack::Fail2Ban.filter(req.ip, :maxretry => 3, :findtime => 10.minutes, :bantime => 5.minutes) do
        # if block is truthy, the count for the IP is incremented
        CGI.unescape(req.query_string) =~ %r{/etc/passwd} 
      end
    end

### Throttles

    # Throttle requests to 5 requests per second per ip
    Rack::Attack.throttle('req/ip', :limit => 5, :period => 1.second) do |req|
      # If the return value is truthy, the cache key for the return value
      # is incremented and compared with the limit. In this case:
      #   "rack::attack:#{Time.now.to_i/1.second}:req/ip:#{req.ip}"
      #
      # If falsy, the cache key is neither incremented nor checked.

      req.ip
    end

    # Throttle login attempts for a given email parameter to 6 reqs/minute
    # Return the email as a discriminator on POST /login requests
    Rack::Attack.throttle('logins/email', :limit => 6, :period => 60.seconds) do |req|
      req.params['email'] if req.path == '/login' && req.post?
    end

### Tracks

    # Track requests from a special user agent
    Rack::Attack.track("special_agent") do |req|
      req.user_agent == "SpecialAgent"
    end

    # Track it using ActiveSupport::Notification
    ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, req|
      if req.env['rack.attack.matched'] == "special_agent" && req.env['rack.attack.match_type'] == :track
        Rails.logger.info "special_agent: #{req.path}"
        STATSD.increment("special_agent")
      end
    end


## Responses

Customize the response of blacklisted and throttled requests using an object that adheres to the [Rack app interface](http://rack.rubyforge.org/doc/SPEC.html).

    Rack::Attack.blacklisted_response = lambda do |env|
      [ 503, {}, ['Blocked']]
    end

    Rack::Attack.throttled_response = lambda do |env|
      # name and other data about the matched throttle
      body = [
        env['rack.attack.matched'],
        env['rack.attack.match_type'],
        env['rack.attack.match_data']
      ].inspect

      [ 503, {}, [body]]
    end

For responses that did not exceed a throttle limit, Rack::Attack annotates the env with match data:

    request.env['rack.attack.throttle_data'][name] # => { :count => n, :period => p, :limit => l }

## Logging & Instrumentation

Rack::Attack uses the [ActiveSupport::Notifications](http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html) API if available.

You can subscribe to 'rack.attack' events and log it, graph it, etc:

    ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, req|
      puts req.inspect
    end

## Testing

A note on developing and testing apps using Rack::Attack - if you are using throttling in particular, you will 
need to enable the cache in your development environment. See [Caching with Rails](http://guides.rubyonrails.org/caching_with_rails.html) 
for more on how to do this. 

## Performance

The overhead of running Rack::Attack is typically negligible (a few milliseconds per request),
but it depends on how many checks you've configured, and how long they take.
Throttles usually require a network roundtrip to your cache server(s),
so try to keep the number of throttle checks per request low.

If a request is blacklisted or throttled, the response is a very simple Rack response.
A single typical ruby web server thread can block several hundred requests per second.

Rack::Attack complements tools like `iptables` and nginx's [limit_zone module](http://wiki.nginx.org/HttpLimitZoneModule).

## Motivation

Abusive clients range from malicious login crackers to naively-written scrapers.
They hinder the security, performance, & availability of web applications.

It is impractical if not impossible to block abusive clients completely.

Rack::Attack aims to let developers quickly mitigate abusive requests and rely
less on short-term, one-off hacks to block a particular attack.

See also: the [Backing & Hacking blog post](http://www.kickstarter.com/backing-and-hacking/rack-attack-protection-from-abusive-clients) introducing Rack::Attack.

[![Build Status](https://travis-ci.org/kickstarter/rack-attack.png?branch=master)](https://travis-ci.org/kickstarter/rack-attack)
[![Code Climate](https://codeclimate.com/github/kickstarter/rack-attack.png)](https://codeclimate.com/github/kickstarter/rack-attack)

## License

Copyright (c) 2012 Kickstarter, Inc

Released under an [MIT License](http://opensource.org/licenses/MIT)
