# Rack::Attack - middleware for throttling & blocking abusive clients

## Processing order
 * If any whitelist matches, the request is allowed
 * If any blacklist matches, the request is blocked (unless a whitelist matched)
 * If any throttle matches, the request is throttled (unless a whitelist or blacklist matched)
