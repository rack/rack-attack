# Changelog
All notable changes to this project will be documented in this file.

## [Unreleased]

_No significant changes since last release yet. Stay tuned_ :radio:

## [5.3.0] - 2018-06-19

### Added

- Add support for [`ActiveSupport::Cache::RedisCacheStore`](http://api.rubyonrails.org/classes/ActiveSupport/Cache/RedisCacheStore.html) as a store backend ([#340](https://github.com/kickstarter/rack-attack/pull/340) and [#350](https://github.com/kickstarter/rack-attack/pull/350))

## [5.2.0] - 2018-03-29

### Added

- Shorthand for blocking an IP address `Rack::Attack.blocklist_ip("1.2.3.4")` ([#320](https://github.com/kickstarter/rack-attack/pull/320))
- Shorthand for blocking an IP subnet `Rack::Attack.blocklist_ip("1.2.0.0/16")` ([#320](https://github.com/kickstarter/rack-attack/pull/320))
- Shorthand for safelisting an IP address `Rack::Attack.safelist_ip("5.6.7.8")` ([#320](https://github.com/kickstarter/rack-attack/pull/320))
- Shorthand for safelisting an IP subnet `Rack::Attack.safelist_ip("5.6.0.0/16")` ([#320](https://github.com/kickstarter/rack-attack/pull/320))
- Throw helpful error message when using `allow2ban` but cache store is misconfigured ([#315](https://github.com/kickstarter/rack-attack/issues/315))
- Throw helpful error message when using `fail2ban` but cache store is misconfigured ([#315](https://github.com/kickstarter/rack-attack/issues/315))

## [5.1.0] - 2018-03-10

  - Fixes edge case bug when using ruby 2.5.0 and redis [#253](https://github.com/kickstarter/rack-attack/issues/253) ([#271](https://github.com/kickstarter/rack-attack/issues/271))
  - Throws errors with better semantics when missing or misconfigured store caches to aid in developers debugging their configs ([#274](https://github.com/kickstarter/rack-attack/issues/274))
  - Removed legacy code that was originally intended for Rails 3 apps ([#264](https://github.com/kickstarter/rack-attack/issues/264))

## [5.0.1] - 2016-08-11

  - Fixes arguments passed to deprecated internal methods. ([#198](https://github.com/kickstarter/rack-attack/issues/198))

## [5.0.0] - 2016-08-09

  - Deprecate `whitelist`/`blacklist` in favor of `safelist`/`blocklist`. ([#181](https://github.com/kickstarter/rack-attack/issues/181),
    thanks @renee-travisci).  To upgrade and fix deprecations, find and replace instances of `whitelist` and `blacklist` with `safelist` and `blocklist`. If you reference `rack.attack.match_type`, note that it will have values like `:safelist`/`:blocklist`.
  - Remove test coverage for unsupported ruby dependencies: ruby 2.0, activesupport 3.2/4.0, and dalli 1.

## [4.4.1] - 2016-02-17

  - Fix a bug affecting apps using Redis::Store and ActiveSupport that could generate an error
    saying dalli was a required dependency. I learned all about ActiveSupport autoloading. ([#165](https://github.com/kickstarter/rack-attack/issues/165))

## [4.4.0] - 2016-02-10

  - New: support for MemCacheStore ([#153](https://github.com/kickstarter/rack-attack/issues/153)). Thanks @elhu.
  - Some documentation and test harness improvements.

## [4.3.1] - 2015-12-18
  - SECURITY FIX: Normalize request paths when using ActionDispatch. Thanks
    Andres Riancho at @includesecurity for reporting it.
  - Remove support for ruby 1.9.x
  - Add Code of Conduct
  - Several documentation and testing improvements

## [4.3.0] - 2015-05-22

  - Redis proxy passes `raw: true` (thanks @stanhu)
  - Redis supports `delete` method to be consistent with Dalli (thanks @stanhu)
  - Support the ability to reset Fail2Ban count and ban flag (thanks @stanhu)

## [4.2.0] - 2014-10-26
 - Throttle's `period` argument now takes a proc as well as a number (thanks @gsamokovarov)
 - Invoke the `#call` method on `blocklist_response` and `throttle_response` instead of `#[]`, as per the Rack spec. (thanks @gsamokovarov)

## [4.1.1] - 2014-09-11
 - Fix a race condition in throttles that could allow more requests than intended.

## [4.1.0] - 2014-05-22
 - Tracks take an optional limit and period to only notify once a threshold
   is reached (similar to throttles). Thanks @chiliburger!
 - Default throttled & blocklist responses have Content-Type: text/plain
 - Rack::Attack.clear! resets tracks

## [4.0.1] - 2014-05-14
 - Add throttle discriminator to rack env (thanks @blahed)

## [4.0.0] - 2014-04-28
 - Implement proxy for Dalli with better Memcachier support. (thanks @hakanensari)
 - Rack::Attack.new returns an instance to ease testing. (thanks @stevehodgkiss)
   [Changing a module to a class is not backwards compatible, hence v4.0.0.]
 - Use Rack::Attack::Request subclass of Rack::Request for easier extending (thanks @tristandunn)
 - Test more dalli versions.

## [3.0.0] - 2014-03-15
 - Change default blocklisted response to 403 Forbidden (thanks @carpodaster).
 - Fail gracefully when Redis store is not available; rescue exeption and don't
   throttle request. (thanks @wkimeria)
 - TravisCI runs integration tests.

## [2.3.0] - 2013-10-11
 - Allow throttle `limit` argument to be a proc. (thanks @lunks)
 - Add Allow2Ban, complement of Fail2Ban. (thanks @jormon)
 - Improved TravisCI testing

## [2.2.1] - 2013-08-13
 - Add license to gemspec
 - Support ruby version 1.9.2
 - Change default blocklisted response code from 503 to 401; throttled response
   from 503 to 429.

## [2.2.0] - 2013-06-20
 - Fail2Ban filtering. See README for details. Thx @madlep!
 - Introduce StoreProxy to more cleanly abstract cache stores. Thx @madlep.

## 2.1.1 - 2013-05-16
 - Start keeping changelog
 - Fix `Redis::CommandError` when using ActiveSupport numeric extensions (e.g. `1.second`)
 - Remove unused variable
 - Extract mandatory options to constants

[Unreleased]: https://github.com/kickstarter/rack-attack/compare/v5.3.0...HEAD/
[5.3.0]: https://github.com/kickstarter/rack-attack/compare/v5.2.0...v5.3.0/
[5.2.0]: https://github.com/kickstarter/rack-attack/compare/v5.1.0...v5.2.0/
[5.1.0]: https://github.com/kickstarter/rack-attack/compare/v5.0.1...v5.1.0/
[5.0.1]: https://github.com/kickstarter/rack-attack/compare/v5.0.0...v5.0.1/
[5.0.0]: https://github.com/kickstarter/rack-attack/compare/v4.4.1...v5.0.0/
[4.4.1]: https://github.com/kickstarter/rack-attack/compare/v4.4.0...v4.4.1/
[4.4.0]: https://github.com/kickstarter/rack-attack/compare/v4.3.1...v4.4.0/
[4.3.1]: https://github.com/kickstarter/rack-attack/compare/v4.3.0...v4.3.1/
[4.3.0]: https://github.com/kickstarter/rack-attack/compare/v4.2.0...v4.3.0/
[4.2.0]: https://github.com/kickstarter/rack-attack/compare/v4.1.1...v4.2.0/
[4.1.1]: https://github.com/kickstarter/rack-attack/compare/v4.1.0...v4.1.1/
[4.1.0]: https://github.com/kickstarter/rack-attack/compare/v4.0.1...v4.1.0/
[4.0.1]: https://github.com/kickstarter/rack-attack/compare/v4.0.0...v4.0.1/
[4.0.0]: https://github.com/kickstarter/rack-attack/compare/v3.0.0...v4.0.0/
[3.0.0]: https://github.com/kickstarter/rack-attack/compare/v2.3.0...v3.0.0/
[2.3.0]: https://github.com/kickstarter/rack-attack/compare/v2.2.1...v2.3.0/
[2.2.1]: https://github.com/kickstarter/rack-attack/compare/v2.2.0...v2.2.1/
[2.2.0]: https://github.com/kickstarter/rack-attack/compare/v2.1.1...v2.2.0/
