require_relative 'spec_helper'

describe 'Rack::Attack.track' do
  class Counter
    def self.incr
      @counter += 1
    end

    def self.reset
      @counter = 0
    end

    def self.check
      @counter
    end
  end

  before do
    Rack::Attack.track("everything"){ |req| true }
  end
  allow_ok_requests
  it "should tag the env" do
    get '/'
    last_request.env['rack.attack.matched'].must_equal 'everything'
    last_request.env['rack.attack.match_type'].must_equal :track
  end

  describe "with a notification subscriber and two tracks" do
    before do
      Counter.reset
      # A second track
      Rack::Attack.track("homepage"){ |req| req.path == "/"}

      ActiveSupport::Notifications.subscribe("rack.attack") do |*args|
        Counter.incr
      end
      get "/"
    end

    it "should notify twice" do
      Counter.check.must_equal 2
    end
  end
end
