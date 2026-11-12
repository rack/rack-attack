# frozen_string_literal: true

require_relative 'spec_helper'
require 'timecop'

[Rack::Attack::Fail2Ban, Rack::Attack::Allow2Ban].each do |klass|
  describe "#{klass}.retry_after" do
    let(:key_prefix) { klass.name.split('::').last.downcase }
    let(:ban_key) { "#{key_prefix}:ban:1.2.3.4" }
    let(:start_time) { Time.at(1_700_000_000.4) }

    before do
      Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
      options = { bantime: 60, findtime: 60, maxretry: 2 }

      Rack::Attack.blocklist('pentest') do |req|
        klass.filter(req.ip, options) { req.query_string =~ /OMGHAX/ }
      end
    end

    after { Timecop.return }

    def ban
      Timecop.freeze(start_time)
      get '/?foo=OMGHAX', {}, 'REMOTE_ADDR' => '1.2.3.4'
      get '/?foo=OMGHAX', {}, 'REMOTE_ADDR' => '1.2.3.4'
    end

    it 'is nil when not banned' do
      _(klass.retry_after('1.2.3.4')).must_be_nil
    end

    it 'stores the ban expiration time' do
      ban

      _(klass.banned?('1.2.3.4')).must_equal true
      _(Rack::Attack.cache.read(ban_key)).must_equal start_time.to_f + 60
    end

    it 'returns the remaining ban time' do
      ban
      _(klass.retry_after('1.2.3.4')).must_equal 60

      Timecop.freeze(start_time + 15)
      _(klass.retry_after('1.2.3.4')).must_equal 45
    end

    it 'rounds partial seconds up' do
      ban

      Timecop.freeze(start_time + 0.25)
      _(klass.retry_after('1.2.3.4')).must_equal 60

      Timecop.freeze(start_time + 59.9)
      _(klass.retry_after('1.2.3.4')).must_equal 1
    end

    it 'does not extend the ban on further requests' do
      ban

      Timecop.freeze(start_time + 30)
      get '/?foo=OMGHAX', {}, 'REMOTE_ADDR' => '1.2.3.4'
      get '/', {}, 'REMOTE_ADDR' => '1.2.3.4'

      _(last_response.status).must_equal 403
      _(klass.retry_after('1.2.3.4')).must_equal 30
    end

    it 'is nil once the ban expires' do
      ban

      Timecop.freeze(start_time + 61)
      _(klass.banned?('1.2.3.4')).must_equal false
      _(klass.retry_after('1.2.3.4')).must_be_nil
    end

    it 'is nil after reset' do
      ban
      klass.reset('1.2.3.4', findtime: 60)

      _(klass.retry_after('1.2.3.4')).must_be_nil
    end

    it 'reads expiration times stored as strings by raw cache stores' do
      Rack::Attack.cache.write(ban_key, (Time.now.to_f + 10.5).to_s, 60)

      _(klass.banned?('1.2.3.4')).must_equal true
      _(klass.retry_after('1.2.3.4')).must_equal 11
    end

    it 'is at least 1 while the ban key has not expired yet' do
      Rack::Attack.cache.write(ban_key, Time.now.to_f - 0.5, 60)

      _(klass.banned?('1.2.3.4')).must_equal true
      _(klass.retry_after('1.2.3.4')).must_equal 1
    end

    [1, '1'].each do |legacy_value|
      it "is nil for legacy bans stored as #{legacy_value.inspect}" do
        Rack::Attack.cache.write(ban_key, legacy_value, 60)

        _(klass.banned?('1.2.3.4')).must_equal true
        _(klass.retry_after('1.2.3.4')).must_be_nil
      end
    end
  end
end
