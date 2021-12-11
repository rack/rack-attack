# frozen_string_literal: true

require_relative 'spec_helper'
require 'rack/attack/adapters/base'

describe 'Rack::Attack::Adapters::Base#with' do
  class DummyAdapter < Rack::Attack::Adapters::Base
    def rescue_from_error
      StandardError
    end
  end

  def self.run_tests
    it 'adds the with method to adapters' do
      _(@adapter.with { 1 }).must_equal 1
    end

    it 'catches specified errors, returning 0' do
      _(@adapter.with { raise StandardError }).must_equal 0
      _(@adapter.with { raise ArgumentError }).must_equal 0
    end

    it 'raises not specified errors' do
      _ { @adapter.with { raise Exception } }.must_raise Exception
    end
  end

  describe 'backends without the with method' do
    before do
      @adapter = DummyAdapter.new(Object.new)
    end

    run_tests
  end

  describe 'backends that have the with method' do
    before do
      backend = Object.new
      def backend.with
        yield 'backend'
      end

      @adapter = DummyAdapter.new(backend)
    end

    run_tests
  end
end
