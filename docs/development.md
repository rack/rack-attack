# Rack::Attack: Development

## Running the tests

You will need both [Redis](https://redis.io/) and [Memcached](https://memcached.org/) running locally and bound to IP `127.0.0.1` on default ports (`6379` for Redis, and `11211` for Memcached) and able to be accessed without authentication.

Install dependencies by running

    $ bundle install

Install test dependencies by running:

    $ bundle exec appraisal install

Then run the test suite by running

    $ bundle exec appraisal rake test
