require_relative 'spec_helper'

describe 'Rack::Attack' do
  allow_ok_requests

  describe ".respond_to_throttled_requests_with" do
    it "sets to a retry later responder" do
      Rack::Attack.respond_to_throttled_requests_with :retry_later
      Rack::Attack.throttle_responder.must_equal Rack::Attack::RetryLaterResponder
    end

    it "sets to add recaptcha" do
      Rack::Attack.respond_to_throttled_requests_with :add_recaptcha
      Rack::Attack.throttle_responder.must_equal Rack::Attack::AddRecaptchaResponder
    end
  end

  describe 'blacklist' do
    before do
      @bad_ip = '1.2.3.4'
      Rack::Attack.blacklist("ip #{@bad_ip}") {|req| req.ip == @bad_ip }
    end

    it('has a blacklist') { Rack::Attack.blacklists.key?("ip #{@bad_ip}") }

    describe "a bad request" do
      before { get '/', {}, 'REMOTE_ADDR' => @bad_ip }
      it "should return a blacklist response" do
        get '/', {}, 'REMOTE_ADDR' => @bad_ip
        last_response.status.must_equal 401
      end
      it "should tag the env" do
        last_request.env['rack.attack.matched'].must_equal "ip #{@bad_ip}"
        last_request.env['rack.attack.match_type'].must_equal :blacklist
      end

      allow_ok_requests
    end

    describe "and whitelist" do
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

end
