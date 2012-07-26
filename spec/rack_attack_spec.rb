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

  describe 'with a block' do
    before do
      @bad_ip = '1.2.3.4'
      Rack::Attack.block("ip #{@bad_ip}") {|req| req.ip == @bad_ip }
    end

    it('has a block') { Rack::Attack.blocks.key?("ip #{@bad_ip}") }

    it "should block bad requests" do
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
      it "should allow whitelists before blocks" do
        get '/', {}, 'REMOTE_ADDR' => @bad_ip, 'HTTP_USER_AGENT' => @good_ua
        last_response.status.must_equal 200
      end
    end
  end


end
