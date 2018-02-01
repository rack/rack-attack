require "rubygems"
require "bundler/setup"

require "minitest/autorun"
require "minitest/pride"
require "rack/test"
require 'active_support'
require 'action_dispatch'

require "rack/attack"

begin
  require 'pry'
rescue LoadError
  #nothing to do here
end

class MiniTest::Spec

  include Rack::Test::Methods

  after do
    Rack::Attack.clear!
    Rack::Attack.instance_variable_set(:@cache, nil)
  end

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

class Minitest::SharedExamples < Module
  include Minitest::Spec::DSL
end
