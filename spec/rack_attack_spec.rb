# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Rack::Attack' do
  it_allows_ok_requests

  describe 'normalizing paths' do
    before do
      Rack::Attack.blocklist("banned_path") { |req| req.path == '/foo' }
    end

    it 'blocks requests with trailing slash' do
      get '/foo/'
      last_response.status.must_equal 403
    end
  end

  describe 'blocklist' do
    before do
      @bad_ip = '1.2.3.4'
      Rack::Attack.blocklist("ip #{@bad_ip}") { |req| req.ip == @bad_ip }
    end

    it('has a blocklist') {
      Rack::Attack.blocklists.key?("ip #{@bad_ip}").must_equal true
    }

    describe "a bad request" do
      before { get '/', {}, 'REMOTE_ADDR' => @bad_ip }

      it "should return a blocklist response" do
        last_response.status.must_equal 403
        last_response.body.must_equal "Forbidden\n"
      end

      it "should tag the env" do
        last_request.env['rack.attack.matched'].must_equal "ip #{@bad_ip}"
        last_request.env['rack.attack.match_type'].must_equal :blocklist
      end

      it_allows_ok_requests
    end

    describe "and safelist" do
      before do
        @good_ua = 'GoodUA'
        Rack::Attack.safelist("good ua") { |req| req.user_agent == @good_ua }
      end

      it('has a safelist') { Rack::Attack.safelists.key?("good ua") }

      describe "with a request match both safelist & blocklist" do
        before { get '/', {}, 'REMOTE_ADDR' => @bad_ip, 'HTTP_USER_AGENT' => @good_ua }

        it "should allow safelists before blocklists" do
          last_response.status.must_equal 200
        end

        it "should tag the env" do
          last_request.env['rack.attack.matched'].must_equal 'good ua'
          last_request.env['rack.attack.match_type'].must_equal :safelist
        end
      end
    end

    describe '#blocklisted_response' do
      it 'should exist' do
        Rack::Attack.blocklisted_response.must_respond_to :call
      end
    end

    describe '#throttled_response' do
      it 'should exist' do
        Rack::Attack.throttled_response.must_respond_to :call
      end
    end
  end
end
