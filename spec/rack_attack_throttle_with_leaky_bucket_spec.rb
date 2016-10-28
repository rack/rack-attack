require_relative 'spec_helper'

describe 'Rack::Attack.throttle_with_leaky_bucket' do
  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.throttle_with_leaky_bucket('ip/sec', :capacity => 1, :leak => 1) { |req| req.ip }
  end

  it('should have a throttle') { Rack::Attack.throttles_with_leaky_bucket.key?('ip/sec') }
  allow_ok_requests

  describe 'a single request' do
    before { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
    it 'should set the counter for one request' do
      key = "rack::attack:ip/sec:1.2.3.4"
      serialized_data = last_request.env['rack.attack.throttle_with_leaky_bucket_data']['ip/sec'][:bucket].serialize
      Rack::Attack.cache.store.read(key).must_equal serialized_data
    end

    it 'should populate throttle data' do
      throttle_data = last_request.env['rack.attack.throttle_with_leaky_bucket_data']['ip/sec']
      assert throttle_data[:leak] == 1
      assert throttle_data[:capacity] == 1
      assert throttle_data[:bucket].value == 1
      throttle_data[:bucket].must_be_instance_of Rack::Attack::LeakyBucket
    end
  end
  describe "with 2 requests" do
    before do
      2.times { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
    end
    it 'should block the last request' do
      last_response.status.must_equal 429
    end
    it 'should tag the env' do
      match_data = last_request.env['rack.attack.match_data']
      assert match_data[:leak] == 1
      assert match_data[:capacity] == 1
      assert match_data[:bucket].value == 1
      assert match_data[:bucket].full?

      last_request.env['rack.attack.matched'].must_equal 'ip/sec'
      last_request.env['rack.attack.match_type'].must_equal :throttle_with_leaky_bucket
      last_request.env['rack.attack.match_discriminator'].must_equal('1.2.3.4')
    end
  end
end

describe 'Rack::Attack.throttle_with_leaky_bucket with leak as proc' do
  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.throttle_with_leaky_bucket('ip/sec', :leak => lambda { |req| 1 }, :capacity => 1) { |req| req.ip }
  end

  allow_ok_requests

  describe 'a single request' do
    before { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
    it 'should set the counter for one request' do
      key = "rack::attack:ip/sec:1.2.3.4"
      serialized_data = last_request.env['rack.attack.throttle_with_leaky_bucket_data']['ip/sec'][:bucket].serialize
      Rack::Attack.cache.store.read(key).must_equal serialized_data
    end

    it 'should populate throttle data' do
      throttle_data = last_request.env['rack.attack.throttle_with_leaky_bucket_data']['ip/sec']
      assert throttle_data[:leak] == 1
    end
  end
end

describe 'Rack::Attack.throttle_with_leaky_bucket with capacity as proc' do
  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.throttle_with_leaky_bucket('ip/sec', :capacity => lambda { |req| 1 }, :leak => 1) { |req| req.ip }
  end

  allow_ok_requests

  describe 'a single request' do
    before { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
    it 'should set the counter for one request' do
      key = "rack::attack:ip/sec:1.2.3.4"
      serialized_data = last_request.env['rack.attack.throttle_with_leaky_bucket_data']['ip/sec'][:bucket].serialize
      Rack::Attack.cache.store.read(key).must_equal serialized_data
    end

    it 'should populate throttle data' do
      throttle_data = last_request.env['rack.attack.throttle_with_leaky_bucket_data']['ip/sec']
      assert throttle_data[:capacity] == 1
    end
  end
end

describe 'Rack::Attack.throttle_with_leaky_bucket with block retuning nil' do
  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.throttle_with_leaky_bucket('ip/sec', :leak => 1, :capacity => 1) { |_| nil }
  end

  allow_ok_requests

  describe 'a single request' do
    before { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
    it 'should not set the counter' do
      key = "rack::attack:ip/sec:1.2.3.4"
      Rack::Attack.cache.store.read(key).must_equal nil
    end

    it 'should not populate throttle data' do
      last_request.env['rack.attack.throttle_with_leaky_bucket_data'].must_equal nil
    end
  end
end
