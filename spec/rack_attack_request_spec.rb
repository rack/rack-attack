# frozen_string_literal: true

require_relative 'spec_helper'

describe 'Rack::Attack' do
  describe 'helpers' do
    before do
      Rack::Attack::Request.define_method :remote_ip do
        ip
      end

      Rack::Attack.safelist('valid IP') do |req|
        req.remote_ip == "127.0.0.1"
      end
    end

    it_allows_ok_requests
  end
end
