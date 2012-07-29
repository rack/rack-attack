# Rack::Attack
A DSL for blocking & thottling abusive clients

Rack::Attack is a rack middleware to protect your web app from bad clients.
It allows *whitelisting*, *blacklisting*, and *thottling* based on arbitrary properties of the request.

Thottle state is stored in a configurable cache (e.g. `Rails.cache`), presumably backed by memcached.

## Installation

Add the [rack-attack](http://rubygems.org/gems/rack-attack) gem to your Gemfile or run

    gem install rack-attack

Tell your app to use the Rack::Attack middleware.
For Rails 3 apps:

    # In config/application.rb
    config.middleware.use Rack::Attack

Or in your `config.ru`:

    use Rack::Attack

Optionally configure the cache store for throttling:

    Rack::Attack.cache.store = my_cache_store # defaults to Rails.cache

Note that `Rack::Attack.cache` is only used for throttling, not blacklisting & whitelisting.

## How it works

The Rack::Attack middleware examines each request against *whitelists*, *blacklists*, and *throttles* that you define. There are none by default.

 * If the request matches any whitelist, the request is allowed. Blacklists and throttles are not checked.
 * If the request matches any blacklist, the request is blocked. Throttles are not checked.
 * If the request matches any throttle, a counter is incremented in the Rack::Attack.cache. If the throttle limit is exceeded, the request is blocked and further throttles are not checked.

## Usage

Define blacklists, throttles, and whitelists.
Note that `req` is a [Rack::Request](http://rack.rubyforge.org/doc/classes/Rack/Request.html) object.

### Blacklists

    # Block requests from 1.2.3.4
    Rack::Attack.blacklist('block 1.2.3.4') do |req|
      # Request are blocked if the return value is truthy
      '1.2.3.4' == req.ip
    end

    # Block logins from a bad user agent
    Rack::Attack.blacklist('block bad UA logins') do |req|
      req.post? && request.path == '/login' && req.user_agent == 'BadUA'
    end

### Throttles

    # Throttle requests to 5 requests per second per ip
    Rack::Attack.throttle('req/ip', :limit => 5, :period => 1.second) do |req|
      # If the return value is truthy, the cache key for "rack::attack:req/ip:#{req.ip}" is incremented and checked.
      # If falsy, the cache key is neither incremented or checked.
      req.ip
    end

    # Throttle login attempts for a given email parameter to 6 reqs/minute
    Rack::Attack.throttle('logins/email', :limit => 6, :period => 60.seconds) do |req|
      req.post? && request.path == '/login' && req.params['email']
    end

### Whitelists

    # Always allow requests from localhost
    # (blacklist & throttles are skipped)
    Rack::Attack.whitelist('allow from localhost') do |req|
      # Requests are allowed if the return value is truthy
      '127.0.0.1' == req.ip
    end

## Responses

Customize the response of throttled requests using an object that adheres to the [Rack app interface](http://rack.rubyforge.org/doc/SPEC.html).

    Rack:Attack.throttled_response = lambda do |env|
      env['rack.attack.throttled'] # name and other data about the matched throttle
      [ 503, {}, ['Throttled']]
    end

Similarly for blacklisted responses:

    Rack:Attack.blacklisted_response = lambda do |env|
      env['rack.attack.blacklisted'] # name of the matched blacklist
      [ 503, {}, ['Blocked']]
    end

## Logging & Instrumentation

## Motivation

Abusive clients range from malicious login crackers to naively-written scrapers.
They hinder the security, performance, & availability of web applications.

It is impractical if not impossible to block abusive clients completely.

Rack::Attack aims to let developers quickly mitigate abusive requests and rely
less on short-term, one-off hacks to block a particular attack.

Rack::Attack complements `iptables` and nginx's [limit_zone module](http://wiki.nginx.org/HttpLimitZoneModule).

## Thanks

Thanks to [Kickstarter](https://github.com/kickstarter) for sponsoring Rack::Attack development

[![Travis CI](https://secure.travis-ci.org/ktheory/rack-attack.png)](http://travis-ci.org/ktheory/rack-attack)
