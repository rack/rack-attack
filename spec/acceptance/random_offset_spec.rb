# frozen_string_literal: true

require_relative "../spec_helper"
require "timecop"

describe "#random offset" do
  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  it "expires randomly by discriminator" do
    Rack::Attack.throttle("by ip", limit: 1, period: 6) do |request|
      request.ip
    end

    addresses = (1..100).map { |i| "1.2.3.#{i}" }

    start_time = Time.gm('2020-01-01 00:00:00')
    Timecop.freeze(start_time) do
      addresses.each do |ip|
        get "/", {}, "REMOTE_ADDR" => ip
        assert_equal 200, last_response.status
      end

      get "/", {}, "REMOTE_ADDR" => "1.2.3.45"
      assert_equal 429, last_response.status

      responses200 = 0
      responses429 = 0
      Timecop.travel(start_time + 1) do
        addresses.each do |ip|
          get "/", {}, "REMOTE_ADDR" => ip
          responses200 += 1 if last_response.status == 200
          responses429 += 1 if last_response.status == 429
        end
      end

      # We would expect about one in six throttles to expire in the
      # first second. The offset_for MD5 hash happens to come out to
      # 15 out of 100. If anything about the algorithm changes, or
      # the addresses or start_time, these values probably would too.
      assert_equal 15, responses200
      assert_equal 85, responses429
    end
  end
end
