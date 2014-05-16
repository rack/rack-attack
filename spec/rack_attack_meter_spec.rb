require_relative 'spec_helper'
describe 'Rack::Attack.meter' do
  before do
    @period = 60 # Use a long period; failures due to cache key rotation less likely
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.meter('ip/sec', :limit => 1, :period => @period) { |req| req.ip }
  end

  it('should have a meter'){ Rack::Attack.meters.key?('ip/sec') }
  allow_ok_requests

  describe 'a single request' do
    before { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
    it 'should set the counter for one request' do
      key = "rack::attack:#{Time.now.to_i/@period}:ip/sec:1.2.3.4"
      Rack::Attack.cache.store.read(key).must_equal 1
    end

    it 'should populate meter data' do
      data = { :count => 1, :limit => 1, :period => @period }
      last_request.env['rack.attack.meter_data']['ip/sec'].must_equal data
    end
  end
  describe "with 2 requests" do
    before do
      2.times { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
    end
    it 'should not block the last request' do
      last_response.status.must_equal 200
    end
    it 'should tag the env' do
      last_request.env['rack.attack.matched'].must_equal 'ip/sec'
      last_request.env['rack.attack.match_type'].must_equal :meter
      last_request.env['rack.attack.match_data'].must_equal({:count => 2, :limit => 1, :period => @period})
      last_request.env['rack.attack.match_discriminator'].must_equal('1.2.3.4')
    end
    it 'should not set a Retry-After header' do
      last_response.headers['Retry-After'].must_be_nil
    end
  end
end

describe 'Rack::Attack.meter with limit as proc' do
  before do
    @period = 60 # Use a long period; failures due to cache key rotation less likely
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.meter('ip/sec', :limit => lambda {|req| 1}, :period => @period) { |req| req.ip }
  end

  allow_ok_requests

  describe 'a single request' do
    before { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
    it 'should set the counter for one request' do
      key = "rack::attack:#{Time.now.to_i/@period}:ip/sec:1.2.3.4"
      Rack::Attack.cache.store.read(key).must_equal 1
    end

    it 'should populate meter data' do
      data = { :count => 1, :limit => 1, :period => @period }
      last_request.env['rack.attack.meter_data']['ip/sec'].must_equal data
    end
  end
end
