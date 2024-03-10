# frozen_string_literal: true

require_relative "../spec_helper"
require "timecop"

describe "postrequest" do
  before do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    Rack::Attack.postrequest("fail2ban for 404") do |request, response|
      Rack::Attack::Fail2Ban.filter(request.ip, maxretry: 2, findtime: 30, bantime: 60) do
        if response.nil?
          false
        else
          response[0] == 404
        end
      end
    end
  end

  it "returns OK for many requests with 200 status" do
    get "/"
    assert_equal 200, last_response.status

    get "/"
    assert_equal 200, last_response.status
  end


  it "returns OK for few requests with 404 status" do
    get "/not_found"
    assert_equal 404, last_response.status

    get "/not_found"
    assert_equal 404, last_response.status
  end

  it "forbids all access after reaching maxretry limit" do
    get "/not_found"
    assert_equal 404, last_response.status

    get "/not_found"
    assert_equal 404, last_response.status

    get "/not_found"
    assert_equal 403, last_response.status

    get "/"
    assert_equal 403, last_response.status
  end

end
