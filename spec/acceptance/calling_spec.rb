# frozen_string_literal: true

require_relative '../spec_helper'

describe '.with_calling' do

  it 'can specify a calling scope' do
    refute Rack::Attack.calling?
    assert_nil Thread.current['rack.attack.calling']

    Rack::Attack.with_calling do
      assert Rack::Attack.calling?
      assert Thread.current['rack.attack.calling']
    end

    refute Rack::Attack.calling?
    assert_nil Thread.current['rack.attack.calling']
  end

  it 'uses RequestStore if available' do
    store = double('RequestStore', store: {})
    stub_const('RequestStore', store)

    refute Rack::Attack.calling?
    assert_nil Thread.current['rack.attack.calling']

    Rack::Attack.with_calling do
      assert Rack::Attack.calling?
      assert store.store['rack.attack.calling']
      assert_nil Thread.current['rack.attack.calling']
    end

    refute Rack::Attack.calling?
    assert_nil store.store['rack.attack.calling']
    assert_nil Thread.current['rack.attack.calling']
  end

  it 'is true within error handler scope' do
    allow(Rack::Attack.cache.store).to receive(:read).and_raise(RuntimeError)

    Rack::Attack.blocklist("fail2ban pentesters") do |request|
      Rack::Attack::Fail2Ban.filter(request.ip, maxretry: 0, bantime: 600, findtime: 30) { true }
    end

    error_raised = false
    Rack::Attack.error_handler = -> (_error) do
      error_raised = true
      assert Rack::Attack.calling?
    end

    refute Rack::Attack.calling?

    get "/", {}, "REMOTE_ADDR" => "1.2.3.4"
    assert error_raised

    refute Rack::Attack.calling?
  end
end
