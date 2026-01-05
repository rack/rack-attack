# frozen_string_literal: true

require_relative 'spec_helper'

if defined?(::ActiveSupport::Notifications)
  describe 'Rack::Attack.track' do
    let(:notifications) { [] }

    before do
      Rack::Attack.track("everything") { |_req| true }
    end

    it_allows_ok_requests

    it "should tag the env" do
      get '/'

      _(last_request.env['rack.attack.matched']).must_equal 'everything'
      _(last_request.env['rack.attack.match_type']).must_equal :track
    end

    describe "with a notification subscriber and two tracks" do
      before do
        # A second track
        Rack::Attack.track("homepage") { |req| req.path == "/" }

        ActiveSupport::Notifications.subscribe("track.rack_attack") do |_name, _start, _finish, _id, payload|
          notifications.push(payload)
        end

        get "/"
      end

      it "should notify twice" do
        _(notifications.size).must_equal 2
      end
    end

    describe "without limit and period options" do
      it "should assign the track filter to a Check instance" do
        track = Rack::Attack.track("homepage") { |req| req.path == "/" }

        _(track.filter.class).must_equal Rack::Attack::Check
      end
    end

    describe "with limit and period options" do
      it "should assign the track filter to a Throttle instance" do
        track = Rack::Attack.track("homepage", limit: 10, period: 10) { |req| req.path == "/" }

        _(track.filter.class).must_equal Rack::Attack::Throttle
      end
    end
  end
end
