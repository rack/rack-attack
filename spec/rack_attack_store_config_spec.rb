require_relative 'spec_helper'

describe 'Store configuration' do
  it "gives clear error when store it's not configured if it's needed" do
    Rack::Attack.throttle('ip/sec', limit: 1, period: 60) { |req| req.ip }

    assert_raises(Rack::Attack::MissingStoreError) do
      get '/'
    end
  end

  it "gives clear error when store isn't configured properly" do
    Rack::Attack.cache.store = Object.new
    Rack::Attack.throttle('ip/sec', limit: 1, period: 60) { |req| req.ip }

    assert_raises(Rack::Attack::MisconfiguredStoreError) do
      get '/'
    end
  end
end
