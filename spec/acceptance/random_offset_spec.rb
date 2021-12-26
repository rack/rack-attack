# frozen_string_literal: true

require_relative "../spec_helper"
require "timecop"

describe "#random offset" do
  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  it "expires predictably" do
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

      assert_equal 0, responses200
      assert_equal 100, responses429
    end
  end
end
