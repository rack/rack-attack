# Rack::Attack!!!
*Rack middleware for blocking & throttling abusive requests*

Rack::Attack is a rack middleware to protect your web app from bad clients.
It allows *whitelisting*, *blacklisting*, *throttling*, and *tracking* based on arbitrary properties of the request.

Throttle and fail2ban state is stored in a configurable cache (e.g. `Rails.cache`), presumably backed by memcached or redis ([at least gem v3.0.0](https://rubygems.org/gems/redis)).

See the [Backing & Hacking blog post](http://www.kickstarter.com/backing-and-hacking/rack-attack-protection-from-abusive-clients) introducing Rack::Attack.

[![Gem Version](https://badge.fury.io/rb/rack-attack.png)](http://badge.fury.io/rb/rack-attack)
[![Build Status](https://travis-ci.org/kickstarter/rack-attack.png?branch=master)](https://travis-ci.org/kickstarter/rack-attack)
[![Code Climate](https://codeclimate.com/github/kickstarter/rack-attack.png)](https://codeclimate.com/github/kickstarter/rack-attack)


## Getting started

Install the [rack-attack](http://rubygems.org/gems/rack-attack) gem; or add it to your Gemfile with bundler:

```ruby
# In your Gemfile
gem 'rack-attack'
```
Tell your app to use the Rack::Attack middleware.
For Rails 3+ apps:

```ruby
# In config/application.rb
config.middleware.use Rack::Attack
```

Or for Rackup files:

```ruby
# In config.ru
use Rack::Attack
```

Add a `rack-attack.rb` file to `config/initializers/`:
```ruby
# In config/initializers/rack-attack.rb
class Rack::Attack
  # your custom configuration...
end
```

*Tip:* The example in the wiki is a great way to get started:
[Example Configuration](https://github.com/kickstarter/rack-attack/wiki/Example-Configuration)

Optionally configure the cache store for throttling or fail2ban filtering:

```ruby
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new # defaults to Rails.cache
```

Note that `Rack::Attack.cache` is only used for throttling and fail2ban filtering; not blacklisting & whitelisting. Your cache store must implement `increment` and `write` like [ActiveSupport::Cache::Store](http://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html).

## How it works

The Rack::Attack middleware compares each request against *whitelists*, *blacklists*, *throttles*, and *tracks* that you define. There are none by default.

 * If the request matches any **whitelist**, it is allowed.
 * Otherwise, if the request matches any **blacklist**, it is blocked.
 * Otherwise, if the request matches any **throttle**, a counter is incremented in the Rack::Attack.cache. If any throttle's limit is exceeded, the request is blocked.
 * Otherwise, all **tracks** are checked, and the request is allowed.

The algorithm is actually more concise in code: See [Rack::Attack.call](https://github.com/kickstarter/rack-attack/blob/master/lib/rack/attack.rb):

```ruby
def call(env)
  req = Rack::Attack::Request.new(env)

  if whitelisted?(req)
    @app.call(env)
  elsif blacklisted?(req)
    self.class.blacklisted_response.call(env)
  elsif throttled?(req)
    self.class.throttled_response.call(env)
  else
    tracked?(req)
    @app.call(env)
  end
end
```

Note: `Rack::Attack::Request` is just a subclass of `Rack::Attack` so that you
can cleanly monkey patch helper methods onto the
[request object](https://github.com/kickstarter/rack-attack/blob/master/lib/rack/attack/request.rb).

## About Tracks

`Rack::Attack.track` doesn't affect request processing. Tracks are an easy way to log and measure requests matching arbitrary attributes.

## Usage

Define whitelists, blacklists, throttles, and tracks as blocks that return truthy values if matched, falsy otherwise. In a Rails app
these go in an initializer in `config/initializers/`.
A [Rack::Request](http://www.rubydoc.info/gems/rack/Rack/Request) object is passed to the block (named 'req' in the examples).

### Whitelists

```ruby
# Always allow requests from localhost
# (blacklist & throttles are skipped)
Rack::Attack.whitelist('allow from localhost') do |req|
  # Requests are allowed if the return value is truthy
  '127.0.0.1' == req.ip || '::1' == req.ip
end
```

### Blacklists

```ruby
# Block requests from 1.2.3.4
Rack::Attack.blacklist('block 1.2.3.4') do |req|
  # Requests are blocked if the return value is truthy
  '1.2.3.4' == req.ip
end

# Block logins from a bad user agent
Rack::Attack.blacklist('block bad UA logins') do |req|
  req.path == '/login' && req.post? && req.user_agent == 'BadUA'
end
```

#### Fail2Ban

`Fail2Ban.filter` can be used within a blacklist to block all requests from misbehaving clients.
This pattern is inspired by [fail2ban](http://www.fail2ban.org/wiki/index.php/Main_Page).
See the [fail2ban documentation](http://www.fail2ban.org/wiki/index.php/MANUAL_0_8#Jail_Options) for more details on
how the parameters work.  For multiple filters, be sure to put each filter in a separate blacklist and use a unique discriminator for each fail2ban filter.

```ruby
# Block suspicious requests for '/etc/password' or wordpress specific paths.
# After 3 blocked requests in 10 minutes, block all requests from that IP for 5 minutes.
Rack::Attack.blacklist('fail2ban pentesters') do |req|
  # `filter` returns truthy value if request fails, or if it's from a previously banned IP
  # so the request is blocked
  Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", :maxretry => 3, :findtime => 10.minutes, :bantime => 5.minutes) do
    # The count for the IP is incremented if the return value is truthy
    CGI.unescape(req.query_string) =~ %r{/etc/passwd} || 
    req.path.include?('/etc/passwd') ||
    req.path.include?('wp-admin') || 
    req.path.include?('wp-login')
    
  end
end
```

Note that `Fail2Ban` filters are not automatically scoped to the blacklist, so when using multiple filters in an application the scoping must be added to the discriminator e.g. `"pentest:#{req.ip}"`.

#### Allow2Ban
`Allow2Ban.filter` works the same way as the `Fail2Ban.filter` except that it *allows* requests from misbehaving
clients until such time as they reach maxretry at which they are cut off as per normal.
```ruby
# Lockout IP addresses that are hammering your login page.
# After 20 requests in 1 minute, block all requests from that IP for 1 hour.
Rack::Attack.blacklist('allow2ban login scrapers') do |req|
  # `filter` returns false value if request is to your login page (but still
  # increments the count) so request below the limit are not blocked until
  # they hit the limit.  At that point, filter will return true and block.
  Rack::Attack::Allow2Ban.filter(req.ip, :maxretry => 20, :findtime => 1.minute, :bantime => 1.hour) do
    # The count for the IP is incremented if the return value is truthy.
    req.path == '/login' and req.post?
  end
end
```


### Throttles

```ruby
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

# You can also set a limit and period using a proc. For instance, after
# Rack::Auth::Basic has authenticated the user:
limit_proc = proc {|req| req.env["REMOTE_USER"] == "admin" ? 100 : 1}
period_proc = proc {|req| req.env["REMOTE_USER"] == "admin" ? 1.second : 1.minute}
Rack::Attack.throttle('req/ip', :limit => limit_proc, :period => period_proc) do |req|
  req.ip
end
```

### Tracks

```ruby
# Track requests from a special user agent.
Rack::Attack.track("special_agent") do |req|
  req.user_agent == "SpecialAgent"
end

# Supports optional limit and period, triggers the notification only when the limit is reached.
Rack::Attack.track("special_agent", :limit => 6, :period => 60.seconds) do |req|
  req.user_agent == "SpecialAgent"
end

# Track it using ActiveSupport::Notification
ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, req|
  if req.env['rack.attack.matched'] == "special_agent" && req.env['rack.attack.match_type'] == :track
    Rails.logger.info "special_agent: #{req.path}"
    STATSD.increment("special_agent")
  end
end
```

## Responses

Customize the response of blacklisted and throttled requests using an object that adheres to the [Rack app interface](http://rack.rubyforge.org/doc/SPEC.html).

```ruby
Rack::Attack.blacklisted_response = lambda do |env|
  # Using 503 because it may make attacker think that they have successfully
  # DOSed the site. Rack::Attack returns 403 for blacklists by default
  [ 503, {}, ['Blocked']]
end

Rack::Attack.throttled_response = lambda do |env|
  # name and other data about the matched throttle
  body = [
    env['rack.attack.matched'],
    env['rack.attack.match_type'],
    env['rack.attack.match_data']
  ].inspect

  # Using 503 because it may make attacker think that they have successfully
  # DOSed the site. Rack::Attack returns 429 for throttling by default
  [ 503, {}, [body]]
end
```

For responses that did not exceed a throttle limit, Rack::Attack annotates the env with match data:

```ruby
request.env['rack.attack.throttle_data'][name] # => { :count => n, :period => p, :limit => l }
```

## Logging & Instrumentation

Rack::Attack uses the [ActiveSupport::Notifications](http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html) API if available.

You can subscribe to 'rack.attack' events and log it, graph it, etc:

```ruby
ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, req|
  puts req.inspect
end
```

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

Rack::Attack complements tools like `iptables` and nginx's [limit_conn_zone module](http://nginx.org/en/docs/http/ngx_http_limit_conn_module.html#limit_conn_zone).

## Motivation

Abusive clients range from malicious login crackers to naively-written scrapers.
They hinder the security, performance, & availability of web applications.

It is impractical if not impossible to block abusive clients completely.

Rack::Attack aims to let developers quickly mitigate abusive requests and rely
less on short-term, one-off hacks to block a particular attack.

## Contributing

Pull requests and issues are greatly appreciated. This project is intended to be
a safe, welcoming space for collaboration, and contributors are expected to
adhere to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Mailing list

New releases of Rack::Attack are announced on
<rack.attack.announce@librelist.com>. To subscribe, just send an email to
<rack.attack.announce@librelist.com>. See the
[archives](http://librelist.com/browser/rack.attack.announce/).

## License

Copyright Kickstarter, Inc.

Released under an [MIT License](http://opensource.org/licenses/MIT).
