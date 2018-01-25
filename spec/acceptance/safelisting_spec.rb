require_relative "../spec_helper"

describe "#safelist" do
  before do
    Rack::Attack.blocklist("block 1.2.3.4") do |request|
      request.ip == "1.2.3.4"
    end

    Rack::Attack.safelist("safe path") do |request|
      request.path == "/safe_space"
    end
  end

  it "forbids request if blocklist condition is true and safelist is false" do
    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 403, last_response.status
  end

  it "succeeds if blocklist condition is false and safelist is false" do
    get "/", {}, "REMOTE_ADDR" => "5.6.7.8"

    assert_equal 200, last_response.status
  end

  it "succeeds request if blocklist condition is false and safelist is true" do
    get "/safe_space", {}, "REMOTE_ADDR" => "5.6.7.8"

    assert_equal 200, last_response.status
  end

  it "succeeds request if both blocklist and safelist conditions are true" do
    get "/safe_space", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 200, last_response.status
  end
end
