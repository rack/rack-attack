# frozen_string_literal: true

require_relative "../spec_helper"
require "timecop"

describe ".failure_cooldown" do

  let(:store) do
    ActiveSupport::Cache::MemoryStore.new
  end
  
  let(:ignored_error) do
    RuntimeError
  end

  before do
    Rack::Attack.cache.store = store
    Rack::Attack.ignored_errors << ignored_error

    Rack::Attack.blocklist("fail2ban pentesters") do |request|
      Rack::Attack::Fail2Ban.filter(request.ip, maxretry: 0, bantime: 600, findtime: 30) { true }
    end
  end

  it 'has default value' do
    assert_equal Rack::Attack.failure_cooldown, 60
  end

  it 'can get and set value' do
    Rack::Attack.failure_cooldown = 123
    assert_equal Rack::Attack.failure_cooldown, 123
  end

  it "allows requests for 60 seconds after an internal error" do
    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 403, last_response.status

    allow(store).to receive(:read).and_raise(ignored_error)

    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 200, last_response.status

    allow(store).to receive(:read).and_call_original

    Timecop.travel(30) do
      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 200, last_response.status
    end

    Timecop.travel(60) do
      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 403, last_response.status
    end
  end

  it 'raises non-ignored error' do
    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 403, last_response.status

    allow(store).to receive(:read).and_raise(ArgumentError)

    assert_raises(ArgumentError) do
      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
    end
  end

  describe 'user-defined cooldown value' do

    before do
      Rack::Attack.failure_cooldown = 100
    end

    it "allows requests for user-defined period after an internal error" do
      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 403, last_response.status

      allow(store).to receive(:read).and_raise(ignored_error)

      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 200, last_response.status

      allow(store).to receive(:read).and_call_original

      Timecop.travel(60) do
        get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

        assert_equal 200, last_response.status
      end

      Timecop.travel(100) do
        get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

        assert_equal 403, last_response.status
      end
    end
  end

  describe 'nil' do

    before do
      Rack::Attack.failure_cooldown = nil
    end

    it 'disables failure cooldown feature' do
      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 403, last_response.status

      allow(store).to receive(:read).and_raise(ignored_error)

      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 200, last_response.status

      allow(store).to receive(:read).and_call_original

      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 403, last_response.status
    end
  end
end
