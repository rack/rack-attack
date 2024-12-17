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

  describe '.call' do
    before do
      allow(store).to receive(:read).and_raise(raised_error)
    end

    describe 'when raising Dalli::DalliError' do
      let(:raised_error) { stub_const('Dalli::DalliError', Class.new(StandardError)) }

      it 'allows the response' do
        get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

        assert_equal 200, last_response.status
      end
    end

    describe 'when raising Redis::BaseError' do
      let(:raised_error) { stub_const('Redis::BaseConnectionError', Class.new(StandardError)) }

      it 'allows the response' do
        get "/", {}, "REMOTE_ADDR" => "1.2.3.4"

        assert_equal 200, last_response.status
      end
    end

    describe 'when raising other error' do
      let(:raised_error) { RuntimeError }

      it 'raises error if not ignored' do
        assert_raises(RuntimeError) do
          get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
        end
      end
    end
  end
end
