require 'rack/attack'
require 'rspec/core'

throttles = Rack::Attack.throttles
blocklists = Rack::Attack.blocklists
safelists = Rack::Attack.safelists
tracks = Rack::Attack.tracks

Rack::Attack.clear!

RSpec.configure do |config|
  config.around(:each, rack_attack: true) do |ex|
    throttles.reduce(Rack::Attack) do |acc, (name, t)|
      acc.throttle(name, {limit: t.limit, period: t.period}, &t.block)
      acc
    end
    blocklists.reduce(Rack::Attack) do |acc, (name, b)|
      acc.blocklist(name, &b.block)
      acc
    end
    safelists.reduce(Rack::Attack) do |acc, (name, s)|
      acc.safelist(name, &s.block)
      acc
    end
    tracks.reduce(Rack::Attack) do |acc, (name, track)|
      acc.track(name, {limit: track.filter.try(:limit), period: track.filter.try(:period)}, track.filter.block)
      acc
    end
    ex.run
    Rack::Attack.clear!
  end
end
