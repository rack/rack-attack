## Advanced Configuration

If you're feeling ambitious or you have a very particular use-case for Rack::Attack, these advanced configurations may help.

:beetle::warning: Much of this code is untested. Copy-paste at your own risk!

### Exponential Backoff

By layering throttles with linearly increasing limits and exponentially increasing periods, you can mimic an exponential backoff throttle. See [#106](https://github.com/rack/rack-attack/issues/106) for more discussion.

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

You can define helpers on requests like `localhost?` or `subdomain` by monkey-patching `Rack::Attack::Request`. See [#73](https://github.com/rack/rack-attack/issues/73) for more discussion.

```ruby
class Rack::Attack::Request < ::Rack::Request
  def localhost?
    ip == "127.0.0.1"
  end
end

Rack::Attack.safelist("localhost") { |req| req.localhost? }
```

### Blocklisting From ENV Variables

You can have `Rack::Attack` configure its blocklists from ENV variables to simplify maintenance. See [#110](https://github.com/rack/rack-attack/issues/110) for more discussion.

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

By doing a bunch of monkey-patching, you can add a helper for resetting specific throttles. The implementation is kind of long, so see [#113](https://github.com/rack/rack-attack/issues/113) for more discussion.

```ruby
Rack::Attack.reset_throttle "logins/email", "user@example.com"
```

### Blocklisting From Rails.cache

You can configure blocklists to check values stored in `Rails.cache` to allow setting blocklists from inside your application. See [#111](https://github.com/rack/rack-attack/issues/111) for more discussion.

```ruby
# Block attacks from IPs in cache
# To add an IP: Rails.cache.write("block 1.2.3.4", true, expires_in: 2.days)
# To remove an IP: Rails.cache.delete("block 1.2.3.4")
Rack::Attack.blocklist("block IP") do |req|
  Rails.cache.read("block #{req.ip}")
end
```

### Throttle Basic Auth Crackers

An example implementation for blocking hackers who spam basic auth attempts. See [#47](https://github.com/rack/rack-attack/issues/47) for more discussion.

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

### Block Based on Response

Sometimes you want to block based on the HTTP response, rather than just the request properties. Common use cases include:

- **Blocking pentesters**: IPs that receive multiple 404 responses are likely scanning for vulnerabilities
- **Blocking brute force attacks**: IPs that receive multiple 401 responses are likely attempting to guess credentials
- **Blocking scrapers**: IPs that trigger many error responses may be poorly configured bots

Since `Rack::Attack` runs as middleware *before* your application processes requests, it cannot directly access response properties. The solution is to create a custom middleware that runs *after* your application and uses `Fail2Ban` to track response properties.

#### Example implementation

First, create a middleware that tracks response status codes. This middleware should be placed in your application (e.g., `app/middleware/response_tracker_middleware.rb` in Rails):

```ruby
# app/middleware/response_tracker_middleware.rb
class ResponseTrackerMiddleware
  # Define filters that will be shared between this middleware and Rack::Attack
  FILTERS = [
    ->(request, condition = nil) do
      # Track IPs that receive 404 responses
      # After 50 404s in 10 seconds, ban the IP for 60 seconds
      Rack::Attack::Fail2Ban.filter("pentesters-#{request.ip}", maxretry: 50, findtime: 10, bantime: 60) { condition }
    end
  ]

  def initialize(app)
    @app = app
  end

  def call(env)
    # Let the application process the request first
    status, headers, body = @app.call(env)

    # Check the response status and update Fail2Ban counters
    request = Rack::Attack::Request.new(env)
    FILTERS.each do |filter|
      # Increment the counter if status is 404
      filter.call(request, status == 404)
    end

    [status, headers, body]
  end
end
```

Next, configure `Rack::Attack` to use the same filter for blocking. Add this to your Rack::Attack initializer (e.g., `config/initializers/rack_attack.rb`):

```ruby
# config/initializers/rack_attack.rb
# Use the same filters defined in ResponseTrackerMiddleware
# This checks if an IP should be blocked, but does NOT increment the counter
ResponseTrackerMiddleware::FILTERS.each do |filter|
  Rack::Attack.blocklist('pentesters by 404') do |request|
    filter.call(request)
  end
end
```

Finally, add the middleware to your application stack.

```ruby
# config/application.rb (for Rails)
config.middleware.use ResponseTrackerMiddleware
```

Or for a Rack application:

```ruby
# config.ru
use Rack::Attack
use ResponseTrackerMiddleware
run YourApp
```

#### How It Works

1. A request comes in and passes through `Rack::Attack` first
2. `Rack::Attack` checks the blocklist, which calls the filter *without* incrementing the counter
3. If the IP is already banned (from previous 404s), the request is blocked with a 403 response
4. If not blocked, the request continues to your application
5. Your application processes the request and returns a response (e.g., 404)
6. `ResponseTrackerMiddleware` runs after your app and checks the status code
7. If status is 404, it increments the Fail2Ban counter for that IP
8. Once the IP exceeds `maxretry` 404s within `findtime`, subsequent requests are blocked

#### Customization

You can adapt this pattern for other use cases:

```ruby
# Block IPs with multiple 401 responses (failed login attempts)
->(request, condition = nil) do
  Rack::Attack::Fail2Ban.filter("login-failures-#{request.ip}", maxretry: 5, findtime: 1.minute, bantime: 10.minutes) { condition }
end

# Then in the middleware:
filter.call(request, status == 401 && request.path == '/login')
```

```ruby
# Block IPs with any 4xx error
->(request, condition = nil) do
  Rack::Attack::Fail2Ban.filter("client-errors-#{request.ip}", maxretry: 10, findtime: 5.minutes, bantime: 1.hour) { condition }
end

# Then in the middleware:
filter.call(request, status >= 400 && status < 500)
```

**Note**: The same filter instance must be used in both the middleware (to increment counters) and the Rack::Attack blocklist (to check if IP should be blocked).

### Match Actions in Rails

Instead of matching the URL with complex regex, it can be much easier to match specific controller actions:

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
