require_relative 'spec_helper'

describe 'Rack::Attack' do
  allow_ok_requests

  describe 'normalizing paths' do
    before do
      Rack::Attack.blocklist("banned_path") {|req| req.path == '/foo' }
    end

    it 'blocks requests with trailing slash' do
      get '/foo/'
      last_response.status.must_equal 403
    end
  end

  describe 'blocklist' do
    before do
      @bad_ip = '1.2.3.4'
      Rack::Attack.blocklist("ip #{@bad_ip}") {|req| req.ip == @bad_ip }
    end

    it('has a blocklist') {
      Rack::Attack.blocklists.key?("ip #{@bad_ip}").must_equal true
    }
    
    it('has a blacklist with a deprication warning') {
      stdout, stderror  = capture_io do
        Rack::Attack.blacklists.key?("ip #{@bad_ip}").must_equal true
      end
      assert_match "[DEPRECATION] 'blacklists' is deprecated.  Please use 'blocklists' instead.", stderror
    }

    describe "a bad request" do
      before { get '/', {}, 'REMOTE_ADDR' => @bad_ip }
      it "should return a blocklist response" do
        get '/', {}, 'REMOTE_ADDR' => @bad_ip
        last_response.status.must_equal 403
        last_response.body.must_equal "Forbidden\n"
      end
      it "should tag the env" do
        last_request.env['rack.attack.matched'].must_equal "ip #{@bad_ip}"
        last_request.env['rack.attack.match_type'].must_equal :blocklist
      end

      allow_ok_requests
    end

    describe "and safelist" do
      before do
        @good_ua = 'GoodUA'
        Rack::Attack.safelist("good ua") {|req| req.user_agent == @good_ua }
      end

      it('has a safelist'){ Rack::Attack.safelists.key?("good ua") }

      it('has a whitelist with a deprication warning') {
        stdout, stderror  = capture_io do
          Rack::Attack.whitelists.key?("good ua")
        end
        assert_match "[DEPRECATION] 'whitelists' is deprecated.  Please use 'safelists' instead.", stderror
      }

      describe "with a request match both safelist & blocklist" do
        before { get '/', {}, 'REMOTE_ADDR' => @bad_ip, 'HTTP_USER_AGENT' => @good_ua }
        it "should allow safelists before blocklists" do
          get '/', {}, 'REMOTE_ADDR' => @bad_ip, 'HTTP_USER_AGENT' => @good_ua
          last_response.status.must_equal 200
        end
        it "should tag the env" do
          last_request.env['rack.attack.matched'].must_equal 'good ua'
          last_request.env['rack.attack.match_type'].must_equal :safelist
        end
      end
    end
  end

end
