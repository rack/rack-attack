# frozen_string_literal: true

require_relative 'spec_helper'

module CacheBypassableSpec
  class FlakyStore
    class Error < StandardError; end

    attr_reader :writes, :reads, :increments, :deletes

    def initialize(raises: nil)
      @raises = raises
      @writes = []
      @reads = []
      @increments = []
      @deletes = []
    end

    def read(key)
      @reads << key
      raise @raises if @raises

      nil
    end

    def write(key, value, opts = {})
      @writes << [key, value, opts]
      raise @raises if @raises

      :ok
    end

    def increment(key, amount, opts = {})
      @increments << [key, amount, opts]
      raise @raises if @raises

      1
    end

    def delete(key)
      @deletes << key
      raise @raises if @raises

      :ok
    end

    def delete_matched(_); end
  end

  class FlakyStoreProxy < Rack::Attack::BaseProxy
    def self.handle?(store)
      store.is_a?(CacheBypassableSpec::FlakyStore)
    end

    def read(key, *args)
      handle_store_error { __getobj__.read(key, *args) }
    end

    def write(key, value, opts = {})
      handle_store_error { __getobj__.write(key, value, opts) }
    end

    def increment(key, amount, opts = {})
      handle_store_error { __getobj__.increment(key, amount, opts) }
    end

    def delete(key)
      handle_store_error { __getobj__.delete(key) }
    end
  end
end

describe "Rack::Attack::Cache bypassable_store_errors integration" do
  before do
    @cache = Rack::Attack::Cache.new(store: nil)
  end

  it "wraps the store with a matching proxy when set via #store=" do
    flaky = CacheBypassableSpec::FlakyStore.new
    @cache.store = flaky
    _(@cache.store).must_be_instance_of CacheBypassableSpec::FlakyStoreProxy
  end

  it "passes bypassable_store_errors to the proxy when set before the store" do
    @cache.bypassable_store_errors = [CacheBypassableSpec::FlakyStore::Error]
    @cache.store = CacheBypassableSpec::FlakyStore.new
    _(@cache.store.bypassable_store_errors).must_equal [CacheBypassableSpec::FlakyStore::Error]
  end

  it "re-wraps the store when bypassable_store_errors is changed after store=" do
    @cache.store = CacheBypassableSpec::FlakyStore.new
    @cache.bypassable_store_errors = :all
    _(@cache.store.bypassable_store_errors).must_equal :all
  end

  it "re-wraps preserving the same underlying raw store" do
    raw = CacheBypassableSpec::FlakyStore.new
    @cache.store = raw
    wrapped_before = @cache.store
    @cache.bypassable_store_errors = [CacheBypassableSpec::FlakyStore::Error]
    _(@cache.store).wont_equal wrapped_before
    _(@cache.store.__getobj__).must_be_same_as raw
  end

  it "propagates cache writes and bypasses configured errors" do
    flaky = CacheBypassableSpec::FlakyStore.new(raises: CacheBypassableSpec::FlakyStore::Error.new("oom"))
    @cache.bypassable_store_errors = [CacheBypassableSpec::FlakyStore::Error]
    @cache.store = flaky

    result = @cache.count("key", 60)
    _(result).must_equal 1
  end

  it "leaves non-proxyable stores untouched" do
    plain = Object.new
    @cache.store = plain
    _(@cache.store).must_be_same_as plain
  end

  it "allows nil store to remain nil" do
    @cache.store = nil
    _(@cache.store).must_be_nil
  end

  it "raises MisconfiguredStoreError when bypassable_store_errors is invalid" do
    flaky = CacheBypassableSpec::FlakyStore.new
    _(-> {
      @cache.bypassable_store_errors = :sometimes
      @cache.store = flaky
    }).must_raise Rack::Attack::MisconfiguredStoreError
  end

  it "re-raises errors not in the bypass list" do
    flaky = CacheBypassableSpec::FlakyStore.new(raises: RuntimeError.new("boom"))
    @cache.bypassable_store_errors = [CacheBypassableSpec::FlakyStore::Error]
    @cache.store = flaky
    _(-> { @cache.count("key", 60) }).must_raise RuntimeError
  end

  it ":none disables any bypass" do
    flaky = CacheBypassableSpec::FlakyStore.new(raises: CacheBypassableSpec::FlakyStore::Error.new("oom"))
    @cache.bypassable_store_errors = :none
    @cache.store = flaky
    _(-> { @cache.count("key", 60) }).must_raise CacheBypassableSpec::FlakyStore::Error
  end
end
