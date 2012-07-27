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

    it "should blacklist bad requests" do
      get '/', {}, 'REMOTE_ADDR' => @bad_ip
      last_response.status.must_equal 503
    end

    allow_ok_requests

    describe "and with a whitelist" do
      before do
        @good_ua = 'GoodUA'
        Rack::Attack.whitelist("good ua") {|req| req.user_agent == @good_ua }
      end

      it('has a whitelist'){ Rack::Attack.whitelists.key?("good ua") }
      it "should allow whitelists before blacklists" do
        get '/', {}, 'REMOTE_ADDR' => @bad_ip, 'HTTP_USER_AGENT' => @good_ua
        last_response.status.must_equal 200
      end
    end
  end

  describe 'with a throttle' do
    before do
      Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
      Rack::Attack.throttle('ip/sec', :limit => 1, :period => 1) { |req| req.ip }
    end

    it('should have a throttle'){ Rack::Attack.throttles.key?('ip/sec') }
    allow_ok_requests

    it 'should set the counter for one request' do
      get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'
      Rack::Attack.cache.store.read('rack::attack:ip/sec:1.2.3.4').must_equal 1
    end

    it 'should block 2 requests' do
      2.times do
        get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'
      end
      last_response.status.must_equal 503
    end
  end


end
