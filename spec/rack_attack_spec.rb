require_relative 'spec_helper'

describe 'Rack::Attack' do
  include Rack::Test::Methods

  def app
    Rack::Builder.new {
      use Rack::Attack
      run lambda {|env| [200, {}, ['Hello World']]}
    }.to_app
  end

  def self.allow_ok_requests
    it "must allow ok requests" do
      get '/', {}, 'REMOTE_ADDR' => '127.0.0.1'
      last_response.status.must_equal 200
      last_response.body.must_equal 'Hello World'
    end
  end

  after { Rack::Attack.clear! }

  allow_ok_requests

  describe 'with a blacklist' do
    before do
      @bad_ip = '1.2.3.4'
      Rack::Attack.blacklist("ip #{@bad_ip}") {|req| req.ip == @bad_ip }
    end

    it('has a blacklist') { Rack::Attack.blacklists.key?("ip #{@bad_ip}") }

    describe "a bad request" do
      before { get '/', {}, 'REMOTE_ADDR' => @bad_ip }
      it "should return a blacklist response" do
        get '/', {}, 'REMOTE_ADDR' => @bad_ip
        last_response.status.must_equal 503
      end
      it "should tag the env" do
        last_request.env['rack.attack.matched'].must_equal "ip #{@bad_ip}"
        last_request.env['rack.attack.match_type'].must_equal :blacklist
      end

      allow_ok_requests
    end

    describe "and with a whitelist" do
      before do
        @good_ua = 'GoodUA'
        Rack::Attack.whitelist("good ua") {|req| req.user_agent == @good_ua }
      end

      it('has a whitelist'){ Rack::Attack.whitelists.key?("good ua") }
      describe "with a request match both whitelist & blacklist" do
        before { get '/', {}, 'REMOTE_ADDR' => @bad_ip, 'HTTP_USER_AGENT' => @good_ua }
        it "should allow whitelists before blacklists" do
          get '/', {}, 'REMOTE_ADDR' => @bad_ip, 'HTTP_USER_AGENT' => @good_ua
          last_response.status.must_equal 200
        end
        it "should tag the env" do
          last_request.env['rack.attack.matched'].must_equal 'good ua'
          last_request.env['rack.attack.match_type'].must_equal :whitelist
        end
      end
    end
  end

  describe 'with a throttle' do
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
        last_request.env['rack.attack.throttle_data']['ip/sec'].must_equal data
      end
    end
    describe "with 2 requests" do
      before do
        2.times { get '/', {}, 'REMOTE_ADDR' => '1.2.3.4' }
      end
      it 'should block the last request' do
        last_response.status.must_equal 503
      end
      it 'should tag the env' do
        last_request.env['rack.attack.matched'].must_equal 'ip/sec'
        last_request.env['rack.attack.match_type'].must_equal :throttle
        last_request.env['rack.attack.match_data'].must_equal({:count => 2, :limit => 1, :period => @period})
      end
      it 'should set a Retry-After header' do
        last_response.headers['Retry-After'].must_equal @period.to_s
      end
    end

  end
end
