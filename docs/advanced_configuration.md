## Advanced Configuration

If you're feeling ambitious or you have a very particular use-case for Rack::Attack, these advanced configurations may help.

:beetle::warning: Much of this code is untested. Copy-paste at your own risk!

### Exponential Backoff

By layering throttles with linearly increasing limits and exponentially increasing periods, you can mimic an exponential backoff throttle. See [#106](https://github.com/kickstarter/rack-attack/issues/106) for more discussion.

```ruby
# Allows 20 requests in 8  seconds
#        40 requests in 64 seconds
#        ...
#        100 requests in 0.38 days (~250 requests/day)
(1..5).each do |level|
  throttle("logins/ip/#{level}", :limit => (20 * level), :period => (8 ** level).seconds) do |req|
    if req.path == '/login' && req.post?
      req.ip
    end
  end
end
```

### Rack::Attack::Request Helpers

You can define helpers on requests like `localhost?` or `subdomain` by monkey-patching `Rack::Attack::Request`. See [#73](https://github.com/kickstarter/rack-attack/issues/73) for more discussion.

```ruby
class Rack::Attack::Request < ::Rack::Request
  def localhost?
    ip == "127.0.0.1"
  end
end

Rack::Attack.safelist("localhost") { |req| req.localhost? }
```

### Blocklisting From ENV Variables

You can have `Rack::Attack` configure its blocklists from ENV variables to simplify maintenance. See [#110](https://github.com/kickstarter/rack-attack/issues/110) for more discussion.

```ruby
class Rack::Attack
  # Split on a comma with 0 or more spaces after it.
  # E.g. ENV['HEROKU_VARIABLE'] = "foo.com, bar.com"
  # spammers = ["foo.com", "bar.com"]
  spammers = ENV['HEROKU_VARIABLE'].split(/,\s*/)

  # Turn spammers array into a regexp
  spammer_regexp = Regexp.union(spammers) # /foo\.com|bar\.com/
  blocklist("block referer spam") do |request|
    request.referer =~ spammer_regexp
  end
end
```

### Reset Specific Throttles

By doing a bunch of monkey-patching, you can add a helper for resetting specific throttles. The implementation is kind of long, so see [#113](https://github.com/kickstarter/rack-attack/issues/113) for more discussion.

```ruby
Rack::Attack.reset_throttle "logins/email", "user@example.com"
```

### Blocklisting From Rails.cache

You can configure blocklists to check values stored in `Rails.cache` to allow setting blocklists from inside your application. See [#111](https://github.com/kickstarter/rack-attack/issues/111) for more discussion.

```ruby
# Block attacks from IPs in cache
# To add an IP: Rails.cache.write("block 1.2.3.4", true, expires_in: 2.days)
# To remove an IP: Rails.cache.delete("block 1.2.3.4")
Rack::Attack.blocklist("block IP") do |req|
  Rails.cache.read("block #{req.ip}")
end
```

### Throttle Basic Auth Crackers

An example implementation for blocking hackers who spam basic auth attempts. See [#47](https://github.com/kickstarter/rack-attack/issues/47) for more discussion.

```ruby
# After 5 requests with incorrect auth in 1 minute,
# block all requests from that IP for 1 hour.
Rack::Attack.blocklist('basic auth crackers') do |req|
  Rack::Attack::Allow2Ban.filter(req.ip, :maxretry => 5, :findtime => 1.minute, :bantime => 1.hour) do
    # Return true if the authorization header is incorrect
    auth = Rack::Auth::Basic::Request.new(req.env)
    auth.credentials != [my_username, my_password]
  end
end
```

### Match Actions in Rails

Instead of matching the URL with complex regex, it can be much easier to mach specific controller actions:

```ruby
Rack::Attack.safelist('unlimited requests') do |request|
  safelist = [
    'controller#action',
    'another_controller#another_action'
  ]
  route = (Rails.application.routes.recognize_path request.url rescue {}) || {}
  action = "#{route[:controller]}##{route[:action]}"
  safelist.any? { |safe| action == safe }
end
```
