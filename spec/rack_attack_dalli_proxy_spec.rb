# frozen_string_literal: true

require_relative 'spec_helper'

module DalliProxySpec
  class FakeDalliClient
    def initialize(raises: nil)
      @raises = raises
    end

    def get(_key)
      bomb_or(:value)
    end

    def set(*_args)
      bomb_or(:ok)
    end

    def incr(*_args)
      bomb_or(1)
    end

    def delete(_key)
      bomb_or(:ok)
    end

    def with
      yield(self)
    end

    private

    def bomb_or(value)
      raise @raises if @raises

      value
    end
  end
end

describe Rack::Attack::StoreProxy::DalliProxy do
  it 'should stub Dalli::Client#with on older clients' do
    proxy = Rack::Attack::StoreProxy::DalliProxy.new(Class.new)
    proxy.with {} # will not raise an error
  end

  describe "bypassable_store_errors" do
    it "uses ['Dalli::DalliError'] as the default bypass list (as a String)" do
      _(Rack::Attack::StoreProxy::DalliProxy.default_bypassable_store_errors)
        .must_equal ['Dalli::DalliError']
    end

    it "bypasses Dalli::DalliError by default on #read" do
      skip 'dalli gem not available' unless defined?(::Dalli::DalliError)
      client = DalliProxySpec::FakeDalliClient.new(raises: Dalli::DalliError.new("server down"))
      proxy = Rack::Attack::StoreProxy::DalliProxy.new(client)
      _(proxy.read("k")).must_be_nil
    end

    it "re-raises non-Dalli errors by default" do
      client = DalliProxySpec::FakeDalliClient.new(raises: ArgumentError.new("boom"))
      proxy = Rack::Attack::StoreProxy::DalliProxy.new(client)
      _(-> { proxy.read("k") }).must_raise ArgumentError
    end

    it "expresses its default as a String class name so no const is resolved eagerly" do
      default = Rack::Attack::StoreProxy::DalliProxy.default_bypassable_store_errors
      _(default).must_be_kind_of Array
      _(default.all? { |entry| entry.is_a?(String) }).must_equal true
    end

    it "user :none disables the default Dalli bypass" do
      skip 'dalli gem not available' unless defined?(::Dalli::DalliError)
      client = DalliProxySpec::FakeDalliClient.new(raises: Dalli::DalliError.new("server down"))
      proxy = Rack::Attack::StoreProxy::DalliProxy.new(client, bypassable_store_errors: :none)
      _(-> { proxy.read("k") }).must_raise Dalli::DalliError
    end

    it "user Array overrides the default Dalli bypass" do
      skip 'dalli gem not available' unless defined?(::Dalli::DalliError)
      client = DalliProxySpec::FakeDalliClient.new(raises: Dalli::DalliError.new("server down"))
      proxy = Rack::Attack::StoreProxy::DalliProxy.new(
        client,
        bypassable_store_errors: [ArgumentError]
      )
      _(-> { proxy.read("k") }).must_raise Dalli::DalliError
    end

    it "user :all bypasses any error" do
      client = DalliProxySpec::FakeDalliClient.new(raises: RuntimeError.new("boom"))
      proxy = Rack::Attack::StoreProxy::DalliProxy.new(client, bypassable_store_errors: :all)
      _(proxy.read("k")).must_be_nil
    end
  end
end
