# Changlog

## [New Releases here](https://github.com/kickstarter/rack-attack/releases)

This file is kept for historical documentation.

## v5.0.0.beta1 4 July 2016

  - Deprecate `whitelist`/`blacklist` in favor of `safelist`/`blocklist`. (#181,
    thanks @renee-travisci).  To upgrade and fix deprecations, find and replace instances of `whitelist` and `blacklist` with `safelist` and `blocklist`. If you reference `rack.attack.match_type`, note that it will have values like `:safelist`/`:blocklist`.
  - Remove test coverage for unsupported ruby dependencies: ruby 2.0, activesupport 3.2/4.0, and dalli 1.

## v4.4.1 17 Feb 2016

  - Fix a bug affecting apps using Redis::Store and ActiveSupport that could generate an error
    saying dalli was a required dependency. I learned all about ActiveSupport autoloading. (#165)

## v4.4.0 - 10 Feb 2016

  - New: support for MemCacheStore (#153). Thanks @elhu.
  - Some documentation and test harness improvements.

## v4.3.1 - 18 Dec 2015
  - SECURITY FIX: Normalize request paths when using ActionDispatch. Thanks
    Andres Riancho at @includesecurity for reporting it.
  - Remove support for ruby 1.9.x
  - Add Code of Conduct
  - Several documentation and testing improvements

## v4.3.0 - 22 May 2015

  - Redis proxy passes `raw: true` (thanks @stanhu)
  - Redis supports `delete` method to be consistent with Dalli (thanks @stanhu)
  - Support the ability to reset Fail2Ban count and ban flag (thanks @stanhu)

## v4.2.0 - 26 Oct 2014
 - Throttle's `period` argument now takes a proc as well as a number (thanks @gsamokovarov)
 - Invoke the `#call` method on `blocklist_response` and `throttle_response` instead of `#[]`, as per the Rack spec. (thanks @gsamokovarov)

## v4.1.1 - 11 Sept 2014
 - Fix a race condition in throttles that could allow more requests than intended.

## v4.1.0 - 22 May 2014
 - Tracks take an optional limit and period to only notify once a threshold
   is reached (similar to throttles). Thanks @chiliburger!
 - Default throttled & blocklist responses have Content-Type: text/plain
 - Rack::Attack.clear! resets tracks

## v4.0.1 - 14 May 2014
 * Add throttle discriminator to rack env (thanks @blahed)

## v4.0.0 - 28 April 2014
 * Implement proxy for Dalli with better Memcachier support. (thanks @hakanensari)
 * Rack::Attack.new returns an instance to ease testing. (thanks @stevehodgkiss)
   [Changing a module to a class is not backwards compatible, hence v4.0.0.]
 * Use Rack::Attack::Request subclass of Rack::Request for easier extending (thanks @tristandunn)
 * Test more dalli versions.

## v3.0.0 - 15 March 2014
 * Change default blocklisted response to 403 Forbidden (thanks @carpodaster).
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
 * Change default blocklisted response code from 503 to 401; throttled response
   from 503 to 429.

## v2.2.0 - 20 June 2013
 * Fail2Ban filtering. See README for details. Thx @madlep!
 * Introduce StoreProxy to more cleanly abstract cache stores. Thx @madlep.

## v2.1.1 - 16 May 2013
 * Start keeping changelog
 * Fix `Redis::CommandError` when using ActiveSupport numeric extensions (e.g. `1.second`)
 * Remove unused variable
 * Extract mandatory options to constants
