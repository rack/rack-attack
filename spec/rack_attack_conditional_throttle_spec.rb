require_relative 'spec_helper'
describe 'Rack::Attack.conditional_throttle' do
  before do
    @period = 60 # Use a long period; failures due to cache key rotation less likely
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.conditional_throttle('login', :limit => 1, :period => @period) { |req| req.ip }
  end

  it('should have a throttle'){ Rack::Attack.throttles.key?('login') }
  allow_ok_requests

  describe 'a single successful request' do
    before { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
    it 'should not set the counter for one request' do
      key = "rack::attack:#{Time.now.to_i/@period}:login:1.2.3.4"
      Rack::Attack.cache.store.read(key).must_equal nil
    end
  end
  describe "with 2 requests" do
    before do
      2.times { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
    end
    it 'should not block the last request' do
      last_response.status.must_equal 200
    end
  end

  describe 'a successful request followed by failed request' do
    before { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
    it 'should increment counter for failed request' do
      key = "rack::attack:#{Time.now.to_i/@period}:login:1.2.3.4"
      Rack::Attack.increment_throttle_counter('login', '1.2.3.4')
      Rack::Attack.cache.store.read(key).must_equal 1
    end
  end

  describe 'a successful request followed by two failed request followed by successful request' do
    before {
      get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'
      @key = "rack::attack:#{Time.now.to_i/@period}:login:1.2.3.4"
      Rack::Attack.increment_throttle_counter('login', '1.2.3.4')
      Rack::Attack.increment_throttle_counter('login', '1.2.3.4')
    }
    it 'should increment counter for failed request' do

      Rack::Attack.cache.store.read(@key).must_equal 2
      get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'
      Rack::Attack.cache.store.read(@key).must_equal 2
      last_response.status.must_equal 429
    end
  end
end

