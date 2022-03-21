# frozen_string_literal: true

require_relative "../spec_helper"
require "timecop"

describe "Customizing throttled response" do
  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    Rack::Attack.throttle("by ip", limit: 1, period: 6) do |request|
      request.ip
    end
  end

  it "uses offset if responder is default" do
    assert Rack::Attack.cache.store.is_a? ActiveSupport::Cache::MemoryStore
    assert_equal 85, count_429_responses
  end

  it "does not use offset if responder is not default and aware is not set" do
    assert_equal false, Rack::Attack.configuration.throttled_responder_is_offset_aware
    Rack::Attack.throttled_responder = lambda do |req|
      [429, {}, ["Throttled"]]
    end
    assert_equal 100, count_429_responses
  end

  it "uses offset if responder is not default and aware is set" do
    Rack::Attack.throttled_responder = lambda do |req|
      [429, {}, ["Throttled"]]
    end
    Rack::Attack.configuration.throttled_responder_is_offset_aware = true
    assert_equal 85, count_429_responses
  end

  # Count the number of responses with 429 status, out of 100 requests,
  # when the clock advances by one second.
  #
  # When this is invoked with a throttle with period 6 active, using
  # a random offset, we would expect about one in six to expire in the
  # first second. For the fixed start_time we're using, the offset_for
  # MD5 hash happens to come out to 15 expired, 85 throttled, out of 100.
  # (If anything about the algorithm changes, that count probably would
  # too.)
  #
  # When using an old-style period, the start_time is at the beginning of
  # the period, since 2020-01-01 00:00:00 == 1577836800 == 262972800*6,
  # and after 1 second we would expect 0 expires, thus 100 of 100 requests
  # to be throttled.

  def count_429_responses
    addresses = (1..100).map { |i| "1.2.3.#{i}" }
    start_time = Time.gm('2020-01-01 00:00:00')
    Timecop.freeze(start_time) do
      initial_200_response_count = 0
      addresses.each do |ip|
        get "/", {}, "REMOTE_ADDR" => ip
        initial_200_response_count += 1 if last_response.status == 200
      end
      assert_equal 100, initial_200_response_count

      final_429_response_count = 0
      Timecop.travel(start_time + 1) do
        addresses.each do |ip|
          get "/", {}, "REMOTE_ADDR" => ip
          final_429_response_count += 1 if last_response.status == 429
        end
      end
      final_429_response_count
    end
  end
end
