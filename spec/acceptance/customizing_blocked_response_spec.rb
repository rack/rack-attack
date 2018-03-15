require_relative "../spec_helper"

describe "Customizing block responses" do
  it "can be customized" do
    Rack::Attack.blocklist("block 1.2.3.4") do |request|
      request.ip == "1.2.3.4"
    end

    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 403, last_response.status

    Rack::Attack.blocklisted_response = lambda do |env|
      [503, {}, ["Blocked"]]
    end

    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

    assert_equal 503, last_response.status
    assert_equal "Blocked", last_response.body
  end
end
