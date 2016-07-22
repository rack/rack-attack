require_relative 'spec_helper'
describe 'Rack::Attack.throttle' do
  before do
    @period = 60 # Use a long period; failures due to cache key rotation less likely
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.throttle('ip/sec', :limit => 1, :period => @period) { |req| req.ip }
  end

  it('should have a throttle'){ Rack::Attack.throttles.key?('ip/sec') }
  allow_ok_requests

  describe 'a single request' do
    before { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
    it 'should set the counter for one request' do
      key = "rack::attack:#{Time.now.to_i/@period}:ip/sec:1.2.3.4"
      Rack::Attack.cache.store.read(key).must_equal 1
    end

    it 'should populate throttle data' do
      data = { :count => 1, :limit => 1, :period => @period }
      last_request.env['rack.attack.throttle_data']['ip/sec'].delete(:expires_in).wont_be_nil
      last_request.env['rack.attack.throttle_data']['ip/sec'].must_equal data
    end
    
    it 'sets RateLimit headers' do
      last_response.headers['X-RateLimit-Limit'].must_equal 1
      last_response.headers['X-RateLimit-Remaining'].must_equal 0
      last_response.headers['X-RateLimit-Reset'].wont_be_nil
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
      last_request.env['rack.attack.matched'].must_equal 'ip/sec'
      last_request.env['rack.attack.match_type'].must_equal :throttle
      last_request.env['rack.attack.match_data'].delete(:expires_in).wont_be_nil
      last_request.env['rack.attack.match_data'].must_equal({:count => 2, :limit => 1, :period => @period})
      last_request.env['rack.attack.match_discriminator'].must_equal('1.2.3.4')
    end
    it 'should set a Retry-After header' do
      last_response.headers['Retry-After'].must_equal @period.to_s
    end
    
    it 'sets RateLimit headers' do
      last_response.headers['X-RateLimit-Limit'].must_equal 1
      last_response.headers['X-RateLimit-Remaining'].must_equal 0
      last_response.headers['X-RateLimit-Reset'].wont_be_nil
    end
  end
end

describe 'Rack::Attack.throttle RateLimit headers' do
  before do
    @period = 60 # Use a long period; failures due to cache key rotation less likely
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.throttle('ip/sec', :limit => 3, :period => @period) { |req| req.ip }
  end
  allow_ok_requests
  
  it 'sets RateLimit-Remaining header' do
    get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'
    last_response.headers['X-RateLimit-Remaining'].must_equal 2
    get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'
    last_response.headers['X-RateLimit-Remaining'].must_equal 1
    get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'
    last_response.headers['X-RateLimit-Remaining'].must_equal 0
    get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'
    last_response.headers['X-RateLimit-Remaining'].must_equal 0
  end
  
  it 'sets RateLimit-Remaining with lower remaining value' do
    Rack::Attack.throttle('ip/sec2', :limit => 2, :period => @period + 10) { |req| req.ip }
    Rack::Attack.throttle('ip/sec3', :limit => 4, :period => @period + 15) { |req| req.ip }
    get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'
    last_response.headers['X-RateLimit-Remaining'].must_equal 1
  end
  
  it 'sets X-RateLimit-Reset with lowest expires_in value if remaining value equal' do
    Rack::Attack.throttle('ip/sec2', :limit => 3, :period => @period + 10) { |req| req.ip }
    Rack::Attack.throttle('ip/sec3', :limit => 3, :period => @period + 15) { |req| req.ip }
    get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'
    data = last_request.env['rack.attack.throttle_data']
    lowest_expire = data.values.min {|a,b| a[:expires_in] <=> b[:expires_in]}[:expires_in]
    last_response.headers['X-RateLimit-Remaining'].must_equal 2
    last_response.headers['X-RateLimit-Reset'].must_equal lowest_expire
  end
end


describe 'Rack::Attack.throttle with limit as proc' do
  before do
    @period = 60 # Use a long period; failures due to cache key rotation less likely
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.throttle('ip/sec', :limit => lambda { |req| 1 }, :period => @period) { |req| req.ip }
  end

  allow_ok_requests

  describe 'a single request' do
    before { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
    it 'should set the counter for one request' do
      key = "rack::attack:#{Time.now.to_i/@period}:ip/sec:1.2.3.4"
      Rack::Attack.cache.store.read(key).must_equal 1
    end

    it 'should populate throttle data' do
      data = { :count => 1, :limit => 1, :period => @period }
      last_request.env['rack.attack.throttle_data']['ip/sec'].delete(:expires_in).wont_be_nil
      last_request.env['rack.attack.throttle_data']['ip/sec'].must_equal data
    end
  end
end

describe 'Rack::Attack.throttle with period as proc' do
  before do
    @period = 60 # Use a long period; failures due to cache key rotation less likely
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.throttle('ip/sec', :limit => lambda { |req| 1 }, :period => lambda { |req| @period }) { |req| req.ip }
  end

  allow_ok_requests

  describe 'a single request' do
    before { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
    it 'should set the counter for one request' do
      key = "rack::attack:#{Time.now.to_i/@period}:ip/sec:1.2.3.4"
      Rack::Attack.cache.store.read(key).must_equal 1
    end

    it 'should populate throttle data' do
      data = { :count => 1, :limit => 1, :period => @period }
      last_request.env['rack.attack.throttle_data']['ip/sec'].delete(:expires_in).wont_be_nil
      last_request.env['rack.attack.throttle_data']['ip/sec'].must_equal data
    end
  end
end

describe 'Rack::Attack.throttle with block retuning nil' do
  before do
    @period = 60
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.throttle('ip/sec', :limit => 1, :period => @period) { |_| nil }
  end

  allow_ok_requests

  describe 'a single request' do
    before { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
    it 'should not set the counter' do
      key = "rack::attack:#{Time.now.to_i/@period}:ip/sec:1.2.3.4"
      Rack::Attack.cache.store.read(key).must_equal nil
    end

    it 'should not populate throttle data' do
      last_request.env['rack.attack.throttle_data'].must_equal nil
    end
  end
end