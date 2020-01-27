**Describe the bug**

A clear and concise description of what the bug is.

**To Reproduce**

Steps to reproduce the behavior:

1. Have a rack-attack config as follows:

```ruby
  # E.g.

  Rack::Attack.cache.store = " ... "

  Rack::Attack.throttle(...

  # And so on

```

2. Start the app server
3. Visit the page with path '....'
4. See error

**Expected behavior**

A clear and concise description of what you expected to happen.

**Screenshots**

If applicable, add screenshots to help explain your problem.

**Environment information (please complete the following information):**

 - rack-attack version:
 - ruby version:
 - rack version:
 - rails version (if using rails):
 - rails environment (if using rails): [e.g. development, production, all]
 - redis gem version (if reporting redis-related issue):
 - redis server version (if reporting redis-related issue):

**Additional context**

Add any other context about the problem you think can help here.
