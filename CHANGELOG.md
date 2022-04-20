# Changelog

All notable changes to this project will be documented in this file.

## [6.x.x] = 2022-xx-xx

### Added

- Added pseudo-random time offsets to throttling. If your application uses a custom throttle lambda to emit RateLimit-style headers, see the README for updated sample code.

## [6.6.1] - 2022-04-14

### Fixed

- Fixes deprecation warning in redis 4.6+ ([@ixti])

## [6.6.0] - 2022-01-29

### Added

- Ability to have access to the `request` object instead of only `env` (still can access env with `request.env`) when
customizing throttle and blocklist responses with new methods `Rack::Attack.blocklisted_responder=` and
`Rack::Attack.throttled_responder=` which yield the request to your lambda. ([@NikolayRys])

### Deprecated

- `Rack::Attack.blocklisted_response=`
- `Rack::Attack.throttled_response=`

## [6.5.0] - 2021-02-07

### Added

- Added ability to normalize throttle discriminator by setting `Rack::Attack.throttle_discriminator_normalizer` (@fatkodima)

  Example:

      Rack::Attack.throttle_discriminator_normalizer = ->(discriminator) { ... }

  or disable default normalization with:

      Rack::Attack.throttle_discriminator_normalizer = nil

### Removed

- Dropped support for ruby v2.4
- Dropped support for rails v5.1

## [6.4.0] - 2021-01-23

### Added

- Added support for ruby v3.0

### Removed

- Dropped support for ruby v2.3

## [6.3.1] - 2020-05-21

### Fixed

- Warning when using `ActiveSupport::Cache::RedisCacheStore` as a cache store with rails 5.2.4.3 (#482) (@rofreg)

## [6.3.0] - 2020-04-26

### Added

- `Rack::Attack.reset!` to reset state (#436) (@fatkodima)
- `Rack::Attack.throttled_response_retry_after_header=` setting that enables a `Retry-After` response header when client is throttled (#440) (@fatkodima)

### Changed

- No longer swallow Redis non-connection errors if Redis is configured as cache store (#450) (@fatkodima)

### Fixed

- `Rack::Attack.clear_configuration` also clears `blocklisted_response` and `throttled_response` back to defaults

## [6.2.2] - 2019-12-18

### Fixed

- Fixed occasional `Redis::FutureNotReady` error (#445) (@fatkodima)

## [6.2.1] - 2019-10-30

### Fixed

- Remove unintended side-effects on Rails app initialization order. It was potentially affecting the order of `config/initializers/*` in respect to gems initializers (#457)

## [6.2.0] - 2019-10-12

### Added

- Failsafe on Redis error replies in RedisCacheStoreProxy (#421) (@cristiangreco)
- Rack::Attack middleware is now auto added for Rails 5.1+ apps to simplify gem setup (#431) (@fatkodima)
- You can disable Rack::Attack with `Rack::Attack.enabled = false` (#431) (@fatkodima)

## [6.1.0] - 2019-07-11

### Added

- Provide throttle discriminator in the env `throttle_data`

## [6.0.0] - 2019-04-17

### Added

- `#blocklist` and `#safelist` name argument (the first one) is now optional.
- Added support to subscribe only to specific event types via `ActiveSupport::Notifications`, e.g. subscribe to the
  `throttle.rack_attack` or the `blocklist.rack_attack` event.

### Changed

- Changed `ActiveSupport::Notifications` event naming to comply with the recommended format.
- Changed `ActiveSupport::Notifications` event so that the 5th yielded argument to the `#subscribe` method is now a
  `Hash` instead of a `Rack::Attack::Request`, to comply with `ActiveSupport`s spec. The original request object is
  still accessible, being the value of the hash's `:request` key.

### Deprecated

- Subscriptions via `ActiveSupport::Notifications` to the `"rack.attack"` event will continue to work (receive event
  notifications), but it is going to be removed in a future version. Replace the event name with `/rack_attack/` to
  continue to be subscribed to all events, or `"throttle.rack_attack"` e.g. for specific type of events only.

### Removed

- Removed support for ruby 2.2.
- Removed support for obsolete memcache-client as a cache store.
- Removed deprecated methods `#blacklist` and `#whitelist` (use `#blocklist` and `#safelist` instead).

## [5.4.2] - 2018-10-30

### Fixed

- Fix unexpected error when using `redis` 3 and any store which is not proxied

### Changed

- Provide better information in `MisconfiguredStoreError` exception message to aid end-user debugging

## [5.4.1] - 2018-09-29

### Fixed

- Make [`ActiveSupport::Cache::MemCacheStore`](http://api.rubyonrails.org/classes/ActiveSupport/Cache/MemCacheStore.html) also work as excepted when initialized with pool options (e.g. `pool_size`). Thank you @jdelStrother.

## [5.4.0] - 2018-07-02

### Added

- Support "plain" `Redis` as a cache store backend ([#280](https://github.com/rack/rack-attack/pull/280)). Thanks @bfad and @ryandv.
- When overwriting `Rack::Attack.throttled_response` you can now access the exact epoch integer that was used for caching
so your custom code is less prone to race conditions ([#282](https://github.com/rack/rack-attack/pull/282)). Thanks @doliveirakn.

### Dependency changes

- Explictly declare ancient `rack 0.x` series as incompatible in gemspec

## [5.3.2] - 2018-06-25

### Fixed

- Don't raise exception `The Redis cache store requires the redis gem` when using [`ActiveSupport::Cache::MemoryStore`](http://api.rubyonrails.org/classes/ActiveSupport/Cache/MemoryStore.html) as a cache store backend

## [5.3.1] - 2018-06-20

### Fixed

- Make [`ActiveSupport::Cache::RedisCacheStore`](http://api.rubyonrails.org/classes/ActiveSupport/Cache/RedisCacheStore.html) also work as excepted when initialized with pool options (e.g. `pool_size`)

## [5.3.0] - 2018-06-19

### Added

- Add support for [`ActiveSupport::Cache::RedisCacheStore`](http://api.rubyonrails.org/classes/ActiveSupport/Cache/RedisCacheStore.html) as a store backend ([#340](https://github.com/rack/rack-attack/pull/340) and [#350](https://github.com/rack/rack-attack/pull/350))

## [5.2.0] - 2018-03-29

### Added

- Shorthand for blocking an IP address `Rack::Attack.blocklist_ip("1.2.3.4")` ([#320](https://github.com/rack/rack-attack/pull/320))
- Shorthand for blocking an IP subnet `Rack::Attack.blocklist_ip("1.2.0.0/16")` ([#320](https://github.com/rack/rack-attack/pull/320))
- Shorthand for safelisting an IP address `Rack::Attack.safelist_ip("5.6.7.8")` ([#320](https://github.com/rack/rack-attack/pull/320))
- Shorthand for safelisting an IP subnet `Rack::Attack.safelist_ip("5.6.0.0/16")` ([#320](https://github.com/rack/rack-attack/pull/320))
- Throw helpful error message when using `allow2ban` but cache store is misconfigured ([#315](https://github.com/rack/rack-attack/issues/315))
- Throw helpful error message when using `fail2ban` but cache store is misconfigured ([#315](https://github.com/rack/rack-attack/issues/315))

## [5.1.0] - 2018-03-10

  - Fixes edge case bug when using ruby 2.5.0 and redis [#253](https://github.com/rack/rack-attack/issues/253) ([#271](https://github.com/rack/rack-attack/issues/271))
  - Throws errors with better semantics when missing or misconfigured store caches to aid in developers debugging their configs ([#274](https://github.com/rack/rack-attack/issues/274))
  - Removed legacy code that was originally intended for Rails 3 apps ([#264](https://github.com/rack/rack-attack/issues/264))

## [5.0.1] - 2016-08-11

  - Fixes arguments passed to deprecated internal methods. ([#198](https://github.com/rack/rack-attack/issues/198))

## [5.0.0] - 2016-08-09

  - Deprecate `whitelist`/`blacklist` in favor of `safelist`/`blocklist`. ([#181](https://github.com/rack/rack-attack/issues/181),
    thanks @renee-travisci).  To upgrade and fix deprecations, find and replace instances of `whitelist` and `blacklist` with `safelist` and `blocklist`. If you reference `rack.attack.match_type`, note that it will have values like `:safelist`/`:blocklist`.
  - Remove test coverage for unsupported ruby dependencies: ruby 2.0, activesupport 3.2/4.0, and dalli 1.

## [4.4.1] - 2016-02-17

  - Fix a bug affecting apps using Redis::Store and ActiveSupport that could generate an error
    saying dalli was a required dependency. I learned all about ActiveSupport autoloading. ([#165](https://github.com/rack/rack-attack/issues/165))

## [4.4.0] - 2016-02-10

  - New: support for MemCacheStore ([#153](https://github.com/rack/rack-attack/issues/153)). Thanks @elhu.
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


[6.6.1]: https://github.com/rack/rack-attack/compare/v6.6.0...v6.6.1/
[6.6.0]: https://github.com/rack/rack-attack/compare/v6.5.0...v6.6.0/
[6.5.0]: https://github.com/rack/rack-attack/compare/v6.4.0...v6.5.0/
[6.4.0]: https://github.com/rack/rack-attack/compare/v6.3.1...v6.4.0/
[6.3.1]: https://github.com/rack/rack-attack/compare/v6.3.0...v6.3.1/
[6.3.0]: https://github.com/rack/rack-attack/compare/v6.2.2...v6.3.0/
[6.2.2]: https://github.com/rack/rack-attack/compare/v6.2.1...v6.2.2/
[6.2.1]: https://github.com/rack/rack-attack/compare/v6.2.0...v6.2.1/
[6.2.0]: https://github.com/rack/rack-attack/compare/v6.1.0...v6.2.0/
[6.1.0]: https://github.com/rack/rack-attack/compare/v6.0.0...v6.1.0/
[6.0.0]: https://github.com/rack/rack-attack/compare/v5.4.2...v6.0.0/
[5.4.2]: https://github.com/rack/rack-attack/compare/v5.4.1...v5.4.2/
[5.4.1]: https://github.com/rack/rack-attack/compare/v5.4.0...v5.4.1/
[5.4.0]: https://github.com/rack/rack-attack/compare/v5.3.2...v5.4.0/
[5.3.2]: https://github.com/rack/rack-attack/compare/v5.3.1...v5.3.2/
[5.3.1]: https://github.com/rack/rack-attack/compare/v5.3.0...v5.3.1/
[5.3.0]: https://github.com/rack/rack-attack/compare/v5.2.0...v5.3.0/
[5.2.0]: https://github.com/rack/rack-attack/compare/v5.1.0...v5.2.0/
[5.1.0]: https://github.com/rack/rack-attack/compare/v5.0.1...v5.1.0/
[5.0.1]: https://github.com/rack/rack-attack/compare/v5.0.0...v5.0.1/
[5.0.0]: https://github.com/rack/rack-attack/compare/v4.4.1...v5.0.0/
[4.4.1]: https://github.com/rack/rack-attack/compare/v4.4.0...v4.4.1/
[4.4.0]: https://github.com/rack/rack-attack/compare/v4.3.1...v4.4.0/
[4.3.1]: https://github.com/rack/rack-attack/compare/v4.3.0...v4.3.1/
[4.3.0]: https://github.com/rack/rack-attack/compare/v4.2.0...v4.3.0/
[4.2.0]: https://github.com/rack/rack-attack/compare/v4.1.1...v4.2.0/
[4.1.1]: https://github.com/rack/rack-attack/compare/v4.1.0...v4.1.1/
[4.1.0]: https://github.com/rack/rack-attack/compare/v4.0.1...v4.1.0/
[4.0.1]: https://github.com/rack/rack-attack/compare/v4.0.0...v4.0.1/
[4.0.0]: https://github.com/rack/rack-attack/compare/v3.0.0...v4.0.0/
[3.0.0]: https://github.com/rack/rack-attack/compare/v2.3.0...v3.0.0/
[2.3.0]: https://github.com/rack/rack-attack/compare/v2.2.1...v2.3.0/
[2.2.1]: https://github.com/rack/rack-attack/compare/v2.2.0...v2.2.1/
[2.2.0]: https://github.com/rack/rack-attack/compare/v2.1.1...v2.2.0/

[@fatkodima]: https://github.com/fatkodima
[@rofreg]: https://github.com/rofreg
[@NikolayRys]: https://github.com/NikolayRys
[@ixti]: https://github.com/ixti
