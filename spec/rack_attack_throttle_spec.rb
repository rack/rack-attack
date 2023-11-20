# frozen_string_literal: true

require_relative 'spec_helper'
require 'timecop'

describe 'Rack::Attack.throttle' do
  before do
    @period = 60
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.throttle('ip/sec', limit: 1, period: @period) { |req| req.ip }
  end

  it('should have a throttle') { Rack::Attack.throttles.key?('ip/sec') }

  it_allows_ok_requests

  describe 'a single request' do
    it 'should set the counter for one request' do
      Timecop.freeze do
        get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'

        key = "rack::attack:#{Time.now.to_i / @period}:ip/sec:1.2.3.4"
        _(Rack::Attack.cache.store.read(key)).must_equal 1
      end
    end

    it 'should populate throttle data' do
      get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'

      data = {
        count: 1,
        limit: 1,
        period: @period,
        epoch_time: Rack::Attack.cache.last_epoch_time.to_i,
        discriminator: "1.2.3.4"
      }

      _(last_request.env['rack.attack.throttle_data']['ip/sec']).must_equal data
    end
  end

  describe "with 2 requests" do
    before do
      Timecop.freeze do
        2.times { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
      end
    end

    it 'should block the last request' do
      _(last_response.status).must_equal 429
    end

    it 'should tag the env' do
      _(last_request.env['rack.attack.matched']).must_equal 'ip/sec'
      _(last_request.env['rack.attack.match_type']).must_equal :throttle

      _(last_request.env['rack.attack.match_data']).must_equal(
        count: 2,
        limit: 1,
        period: @period,
        epoch_time: Rack::Attack.cache.last_epoch_time.to_i,
        discriminator: "1.2.3.4"
      )

      _(last_request.env['rack.attack.match_discriminator']).must_equal('1.2.3.4')
    end
  end
end

describe 'Rack::Attack.throttle with limit as proc' do
  before do
    @period = 60
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.throttle('ip/sec', limit: lambda { |_req| 1 }, period: @period) { |req| req.ip }
  end

  it_allows_ok_requests

  describe 'a single request' do
    it 'should set the counter for one request' do
      Timecop.freeze do
        get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'

        key = "rack::attack:#{Time.now.to_i / @period}:ip/sec:1.2.3.4"
        _(Rack::Attack.cache.store.read(key)).must_equal 1
      end
    end

    it 'should populate throttle data' do
      get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'
      data = {
        count: 1,
        limit: 1,
        period: @period,
        epoch_time: Rack::Attack.cache.last_epoch_time.to_i,
        discriminator: "1.2.3.4"
      }

      _(last_request.env['rack.attack.throttle_data']['ip/sec']).must_equal data
    end
  end
end

describe 'Rack::Attack.throttle with period as proc' do
  before do
    @period = 60
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.throttle('ip/sec', limit: lambda { |_req| 1 }, period: lambda { |_req| @period }) { |req| req.ip }
  end

  it_allows_ok_requests

  describe 'a single request' do
    it 'should set the counter for one request' do
      Timecop.freeze do
        get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'

        key = "rack::attack:#{Time.now.to_i / @period}:ip/sec:1.2.3.4"
        _(Rack::Attack.cache.store.read(key)).must_equal 1
      end
    end

    it 'should populate throttle data' do
      get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'

      data = {
        count: 1,
        limit: 1,
        period: @period,
        epoch_time: Rack::Attack.cache.last_epoch_time.to_i,
        discriminator: "1.2.3.4"
      }

      _(last_request.env['rack.attack.throttle_data']['ip/sec']).must_equal data
    end
  end
end

describe 'Rack::Attack.throttle with block returning nil' do
  before do
    @period = 60
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.throttle('ip/sec', limit: 1, period: @period) { |_| nil }
  end

  it_allows_ok_requests

  describe 'a single request' do
    it 'should not set the counter' do
      Timecop.freeze do
        get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'

        key = "rack::attack:#{Time.now.to_i / @period}:ip/sec:1.2.3.4"
        assert_nil Rack::Attack.cache.store.read(key)
      end
    end

    it 'should not populate throttle data' do
      get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'
      assert_nil last_request.env['rack.attack.throttle_data']
    end
  end
end

describe 'Rack::Attack.throttle with throttle_discriminator_normalizer' do
  before do
    @period = 60
    @emails = [
      "person@example.com",
      "PERSON@example.com ",
      " person@example.com\r\n  ",
    ]
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.throttle('logins/email', limit: 4, period: @period) do |req|
      if req.path == '/login' && req.post?
        req.params['email']
      end
    end
  end

  it 'should not differentiate requests when throttle_discriminator_normalizer is enabled' do
    Timecop.freeze do
      post_logins
      key = "rack::attack:#{Time.now.to_i / @period}:logins/email:person@example.com"
      _(Rack::Attack.cache.store.read(key)).must_equal 3
    end
  end

  it 'should differentiate requests when throttle_discriminator_normalizer is disabled' do
    begin
      prev = Rack::Attack.throttle_discriminator_normalizer
      Rack::Attack.throttle_discriminator_normalizer = nil

      Timecop.freeze do
        post_logins
        @emails.each do |email|
          key = "rack::attack:#{Time.now.to_i / @period}:logins/email:#{email}"
          _(Rack::Attack.cache.store.read(key)).must_equal 1
        end
      end
    ensure
      Rack::Attack.throttle_discriminator_normalizer = prev
    end
  end

  def post_logins
    @emails.each do |email|
      post '/login', email: email
    end
  end
end
