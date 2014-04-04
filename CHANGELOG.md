# Changlog

## master (unreleased)
 * Implement proxy for Dalli with better Memcachier support. (thanks @hakanensari)
 * Rack::Attack.new returns an instance to ease testing (thanks @stevehodgkiss)

## v3.0.0 - 15 March 2014
 * Change default blacklisted response to 403 Forbidden (thanks @carpodaster).
 * Fail gracefully when Redis store is not available; rescue exeption and don't
   throttle request. (thanks @wkimeria)
 * TravisCI runs integration tests.

## v2.3.0 - 11 October 2013
 * Allow throttle `limit` argument to be a proc. (thanks @lunks)
 * Add Allow2Ban, complement of Fail2Ban. (thanks @jormon)
 * Improved TravisCI testing

## v2.2.1 - 13 August 2013
 * Add license to gemspec
 * Support ruby version 1.9.2
 * Change default blacklisted response code from 503 to 401; throttled response
   from 503 to 429.

## v2.2.0 - 20 June 2013
 * Fail2Ban filtering. See README for details. Thx @madlep!
 * Introduce StoreProxy to more cleanly abstract cache stores. Thx @madlep.

## v2.1.1 - 16 May 2013
 * Start keeping changelog
 * Fix `Redis::CommandError` when using ActiveSupport numeric extensions (e.g. `1.second`)
 * Remove unused variable
 * Extract mandatory options to constants
