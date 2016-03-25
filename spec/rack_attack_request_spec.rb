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

    it 'lazily instantiates and memoizes an IPAddr object around the ip' do
      req = Rack::Attack::Request.new({'REMOTE_ADDR' => '1.2.3.4'})
      ip_addr = req.ip_addr

      ip_addr.must_be_instance_of IPAddr
      ip_addr.must_be_same_as req.ip_addr
    end
  end
end
