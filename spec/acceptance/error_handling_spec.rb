# frozen_string_literal: true

require_relative "../spec_helper"

describe "error handling" do

  let(:store) do
    ActiveSupport::Cache::MemoryStore.new
  end

  before do
    Rack::Attack.cache.store = store

    Rack::Attack.blocklist("fail2ban pentesters") do |request|
      Rack::Attack::Fail2Ban.filter(request.ip, maxretry: 0, bantime: 600, findtime: 30) { true }
    end
  end

  describe '.ignored_errors' do
    before do
      allow(store).to receive(:read).and_raise(RuntimeError)
    end

    it 'has default value' do
      assert_equal Rack::Attack.ignored_errors, %w[Dalli::DalliError Redis::BaseError]
    end

    it 'can get and set value' do
      Rack::Attack.ignored_errors = %w[Foobar]
      assert_equal Rack::Attack.ignored_errors, %w[Foobar]
    end

    it 'can ignore error as Class' do
      Rack::Attack.ignored_errors = [RuntimeError]

      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 200, last_response.status
    end

    it 'can ignore error ancestor as Class' do
      Rack::Attack.ignored_errors = [StandardError]

      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 200, last_response.status
    end

    it 'can ignore error as String' do
      Rack::Attack.ignored_errors = %w[RuntimeError]

      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 200, last_response.status
    end

    it 'can ignore error error ancestor as String' do
      Rack::Attack.ignored_errors = %w[StandardError]

      get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

      assert_equal 200, last_response.status
    end

    it 'raises error if not ignored' do
      assert_raises(RuntimeError) do
        get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
      end
    end
  end

  describe '.ignored_errors?' do

    it 'can match String or Class' do
      Rack::Attack.ignored_errors = ['ArgumentError', RuntimeError]
      assert Rack::Attack.ignored_error?(ArgumentError.new)
      assert Rack::Attack.ignored_error?(RuntimeError.new)
      refute Rack::Attack.ignored_error?(StandardError.new)
    end

    it 'can match Class ancestors' do
      Rack::Attack.ignored_errors = [StandardError]
      assert Rack::Attack.ignored_error?(ArgumentError.new)
      refute Rack::Attack.ignored_error?(Exception.new)
    end

    it 'can match String ancestors' do
      Rack::Attack.ignored_errors = ['StandardError']
      assert Rack::Attack.ignored_error?(ArgumentError.new)
      refute Rack::Attack.ignored_error?(Exception.new)
    end
  end

  describe '.error_handler' do
    before do
      Rack::Attack.error_handler = error_handler if defined?(error_handler)
      allow(store).to receive(:read).and_raise(ArgumentError)
    end

    it 'can get and set value' do
      Rack::Attack.error_handler = :test
      assert_equal Rack::Attack.error_handler, :test
    end

    describe 'Proc which returns :block' do
      let(:error_handler) { ->(_error) { :block } }

      it 'blocks the request' do
        get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

        assert_equal 403, last_response.status
      end
    end

    describe 'Proc which returns :throttle' do
      let(:error_handler) { ->(_error) { :throttle } }

      it 'throttles the request' do
        get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

        assert_equal 429, last_response.status
      end
    end

    describe 'Proc which returns :allow' do
      let(:error_handler) { ->(_error) { :allow } }

      it 'allows the request' do
        get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

        assert_equal 200, last_response.status
      end
    end

    describe 'Proc which returns nil' do
      let(:error_handler) { ->(_error) { nil } }

      it 'allows the request' do
        get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

        assert_equal 200, last_response.status
      end
    end

    describe 'Proc which re-raises the error' do
      let(:error_handler) { ->(error) { raise error } }

      it 'raises the error' do
        assert_raises(ArgumentError) do
          get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
        end
      end
    end

    describe ':block' do
      let(:error_handler) { :block }

      it 'blocks the request' do
        get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

        assert_equal 403, last_response.status
      end
    end

    describe ':throttle' do
      let(:error_handler) { :throttle }

      it 'throttles the request' do
        get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

        assert_equal 429, last_response.status
      end
    end

    describe ':allow' do
      let(:error_handler) { :allow }

      it 'allows the request' do
        get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

        assert_equal 200, last_response.status
      end
    end

    describe 'non-nil value' do
      let(:error_handler) { true }

      it 'allows the request' do
        get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

        assert_equal 200, last_response.status
      end
    end

    describe 'nil' do
      let(:error_handler) { nil }

      it 'raises the error' do
        assert_raises(ArgumentError) do
          get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
        end
      end
    end

    describe 'when error ignored' do
      let(:error_handler) { :throttle }

      before do
        Rack::Attack.ignored_errors = [ArgumentError]
      end

      it 'calls handler despite ignored error' do
        get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

        assert_equal 429, last_response.status
      end
    end
  end
end
