require_relative "../spec_helper"

describe "#blocklist" do
  before do
    Rack::Attack.blocklist("block 1.2.3.4") do |request|
      request.ip == "1.2.3.4"
    end
  end

  it "forbids request if blocklist condition is true" do
    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 403, last_response.status
  end

  it "succeeds if blocklist condition is false" do
    get "/", {}, "REMOTE_ADDR" => "5.6.7.8"

    assert_equal 200, last_response.status
  end
end
