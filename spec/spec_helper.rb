require "rubygems"
require "bundler/setup"

require "minitest/autorun"
require "rack/test"
require 'debugger'
require 'active_support'

require "rack/attack"

class Minitest::Spec

  include Rack::Test::Methods

  after { Rack::Attack.clear! }

  def app
    Rack::Builder.new {
      use Rack::Attack
      run lambda {|env| [200, {}, ['Hello World']]}
    }.to_app
  end

  def self.allow_ok_requests
    it "must allow ok requests" do
      get '/', {}, 'REMOTE_ADDR' => '127.0.0.1'
      last_response.status.must_equal 200
      last_response.body.must_equal 'Hello World'
    end
  end
end
