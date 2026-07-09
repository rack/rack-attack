# frozen_string_literal: true

require_relative 'spec_helper'

module BaseProxySpec
  CustomError = Class.new(StandardError)
  SubCustomError = Class.new(CustomError)
  OtherError = Class.new(StandardError)
  DefaultError = Class.new(StandardError)
  ClassDefaultError = Class.new(StandardError)

  class TestProxy < Rack::Attack::BaseProxy
    def self.handle?(store)
      store.is_a?(Hash) && store[:test_proxy]
    end

    def call_handle_store_error(&block)
      handle_store_error(&block)
    end
  end

  class DefaultsProxy < Rack::Attack::BaseProxy
    def self.handle?(_store)
      false
    end

    def self.default_bypassable_store_errors
      ['BaseProxySpec::DefaultError', BaseProxySpec::ClassDefaultError]
    end

    def call_handle_store_error(&block)
      handle_store_error(&block)
    end
  end
end

describe Rack::Attack::BaseProxy do
  describe "#initialize" do
    it "defaults bypassable_store_errors to [] when proxy has no default" do
      proxy = BaseProxySpec::TestProxy.new(Object.new)
      _(proxy.bypassable_store_errors).must_equal []
    end

    it "uses the subclass default when bypassable_store_errors is not provided" do
      proxy = BaseProxySpec::DefaultsProxy.new(Object.new)
      _(proxy.bypassable_store_errors).must_include 'BaseProxySpec::DefaultError'
      _(proxy.bypassable_store_errors).must_include BaseProxySpec::ClassDefaultError
    end

    it "accepts :all" do
      proxy = BaseProxySpec::TestProxy.new(Object.new, bypassable_store_errors: :all)
      _(proxy.bypassable_store_errors).must_equal :all
    end

    it "accepts :none" do
      proxy = BaseProxySpec::TestProxy.new(Object.new, bypassable_store_errors: :none)
      _(proxy.bypassable_store_errors).must_equal :none
    end

    it "accepts an Array of Classes" do
      proxy = BaseProxySpec::TestProxy.new(Object.new, bypassable_store_errors: [BaseProxySpec::CustomError])
      _(proxy.bypassable_store_errors).must_equal [BaseProxySpec::CustomError]
    end

    it "accepts an Array of String class names" do
      proxy = BaseProxySpec::TestProxy.new(Object.new, bypassable_store_errors: ['BaseProxySpec::CustomError'])
      _(proxy.bypassable_store_errors).must_equal ['BaseProxySpec::CustomError']
    end

    it "accepts a mixed Array of Classes and Strings" do
      proxy = BaseProxySpec::TestProxy.new(
        Object.new,
        bypassable_store_errors: [BaseProxySpec::CustomError, 'Other']
      )
      _(proxy.bypassable_store_errors).must_equal [BaseProxySpec::CustomError, 'Other']
    end

    it "user-provided value overrides subclass default" do
      proxy = BaseProxySpec::DefaultsProxy.new(
        Object.new,
        bypassable_store_errors: [BaseProxySpec::CustomError]
      )
      _(proxy.bypassable_store_errors).must_equal [BaseProxySpec::CustomError]
    end

    it ":none overrides subclass default to bypass nothing" do
      proxy = BaseProxySpec::DefaultsProxy.new(Object.new, bypassable_store_errors: :none)
      _(proxy.bypassable_store_errors).must_equal :none
    end

    it "raises MisconfiguredStoreError for unsupported Symbol" do
      error = _(-> {
        BaseProxySpec::TestProxy.new(Object.new, bypassable_store_errors: :sometimes)
      }).must_raise Rack::Attack::MisconfiguredStoreError
      _(error.message).must_match(/:all, :none/)
    end

    it "raises MisconfiguredStoreError for non-Array, non-Symbol value" do
      _(-> {
        BaseProxySpec::TestProxy.new(Object.new, bypassable_store_errors: "Redis::Error")
      }).must_raise Rack::Attack::MisconfiguredStoreError
    end

    it "raises MisconfiguredStoreError for an Array containing invalid entries" do
      _(-> {
        BaseProxySpec::TestProxy.new(Object.new, bypassable_store_errors: [BaseProxySpec::CustomError, 42])
      }).must_raise Rack::Attack::MisconfiguredStoreError
    end

    it "accepts an empty Array as 'bypass nothing'" do
      proxy = BaseProxySpec::TestProxy.new(Object.new, bypassable_store_errors: [])
      _(proxy.bypassable_store_errors).must_equal []
    end
  end

  describe "#handle_store_error" do
    it "returns the block's result when it does not raise" do
      proxy = BaseProxySpec::TestProxy.new(Object.new, bypassable_store_errors: [BaseProxySpec::CustomError])
      result = proxy.call_handle_store_error { 42 }
      _(result).must_equal 42
    end

    it "bypasses matching error class and returns nil" do
      proxy = BaseProxySpec::TestProxy.new(Object.new, bypassable_store_errors: [BaseProxySpec::CustomError])
      result = proxy.call_handle_store_error { raise BaseProxySpec::CustomError, "boom" }
      _(result).must_be_nil
    end

    it "bypasses subclass of a matching error class" do
      proxy = BaseProxySpec::TestProxy.new(Object.new, bypassable_store_errors: [BaseProxySpec::CustomError])
      result = proxy.call_handle_store_error { raise BaseProxySpec::SubCustomError, "boom" }
      _(result).must_be_nil
    end

    it "bypasses matching error by String class name" do
      proxy = BaseProxySpec::TestProxy.new(
        Object.new,
        bypassable_store_errors: ['BaseProxySpec::CustomError']
      )
      result = proxy.call_handle_store_error { raise BaseProxySpec::CustomError, "boom" }
      _(result).must_be_nil
    end

    it "bypasses subclass error when ancestor name is configured as String" do
      proxy = BaseProxySpec::TestProxy.new(
        Object.new,
        bypassable_store_errors: ['BaseProxySpec::CustomError']
      )
      result = proxy.call_handle_store_error { raise BaseProxySpec::SubCustomError, "boom" }
      _(result).must_be_nil
    end

    it "re-raises unmatched errors" do
      proxy = BaseProxySpec::TestProxy.new(Object.new, bypassable_store_errors: [BaseProxySpec::CustomError])
      _(-> {
        proxy.call_handle_store_error { raise BaseProxySpec::OtherError, "nope" }
      }).must_raise BaseProxySpec::OtherError
    end

    it "re-raises all errors when bypassable_store_errors is :none" do
      proxy = BaseProxySpec::TestProxy.new(Object.new, bypassable_store_errors: :none)
      _(-> {
        proxy.call_handle_store_error { raise BaseProxySpec::CustomError, "boom" }
      }).must_raise BaseProxySpec::CustomError
    end

    it "bypasses all errors when bypassable_store_errors is :all" do
      proxy = BaseProxySpec::TestProxy.new(Object.new, bypassable_store_errors: :all)
      result = proxy.call_handle_store_error { raise RuntimeError, "anything" }
      _(result).must_be_nil
    end

    it "bypasses errors using default list when no override is provided" do
      proxy = BaseProxySpec::DefaultsProxy.new(Object.new)
      result_a = proxy.call_handle_store_error { raise BaseProxySpec::DefaultError, "boom" }
      _(result_a).must_be_nil
      result_b = proxy.call_handle_store_error { raise BaseProxySpec::ClassDefaultError, "boom" }
      _(result_b).must_be_nil
    end

    it "re-raises errors not in the default list" do
      proxy = BaseProxySpec::DefaultsProxy.new(Object.new)
      _(-> {
        proxy.call_handle_store_error { raise BaseProxySpec::OtherError, "nope" }
      }).must_raise BaseProxySpec::OtherError
    end
  end

  describe "String ancestor matching" do
    it "ignores String entries whose name matches no ancestor" do
      proxy = BaseProxySpec::TestProxy.new(
        Object.new,
        bypassable_store_errors: ['DoesNotExist::Error']
      )
      _(-> {
        proxy.call_handle_store_error { raise BaseProxySpec::CustomError, "boom" }
      }).must_raise BaseProxySpec::CustomError
    end

    it "works even if the referenced constant is not loaded" do
      proxy = BaseProxySpec::TestProxy.new(
        Object.new,
        bypassable_store_errors: ['Totally::Unknown']
      )
      _(-> {
        proxy.call_handle_store_error { raise BaseProxySpec::CustomError, "boom" }
      }).must_raise BaseProxySpec::CustomError
    end
  end
end
