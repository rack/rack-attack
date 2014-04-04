require_relative 'spec_helper'

describe 'Rack::Attack' do
  describe 'helpers' do
    before do
      class Rack::Attack::Request
        def remote_ip
          ip
        end
      end

      Rack::Attack.whitelist('valid IP') do |req|
        req.remote_ip == "127.0.0.1"
      end
    end

    allow_ok_requests
  end
end
