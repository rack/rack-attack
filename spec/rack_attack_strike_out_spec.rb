require_relative 'spec_helper'
require 'cgi'
describe 'Rack::Attack.strike_out' do
  before do
    @period = 60 # Use a long period; failures due to cache key rotation less likely
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.strike_out('pentest', :limit => 2, :period => @period) { |req|
      strike! if CGI.unescape(req.query_string) =~ %r{/etc/passwd}
      req.ip
    }
  end

  it('must have a throttle'){ Rack::Attack.strike_outs.key?('pentest') }
  allow_ok_requests

  describe 'strike!' do
    before { get '/foo/bar?hax=/etc/passwd', {}, 'REMOTE_ADDR' => '1.2.3.4' }
    it "must bump the strike_out count" do
      key = "rack::attack:#{Time.now.to_i/@period}:pentest:1.2.3.4"
      Rack::Attack.cache.store.read(key).must_equal 1
    end

    it "must report the matched name" do
      last_request.env['rack.attack.matched'].must_equal 'pentest'
    end

    it "must report the match_type" do
      last_request.env['rack.attack.match_type'].must_equal :strike
    end

    it "must populate the request data" do
      data = { :count => 1, :limit => 2, :period => @period, :struck_out => false }
      last_request.env['rack.attack.strike_out_data']['pentest'].must_equal data
    end

    it "must block the request" do
      last_response.status.must_equal 503
    end

    describe 'when count is not at strike out limit' do
      it "must not strike out the client" do
        key = "rack::attack:pentest:1.2.3.4"
        Rack::Attack.cache.store.read(key).must_be :nil?
      end
    end

    describe 'when count is at strike out limit' do
      it "must strike out the client" do
        get '/foo/bar?hax=/etc/passwd', {}, 'REMOTE_ADDR' => '1.2.3.4' # hit me again to tip it over
        key = "rack::attack:pentest:1.2.3.4"
        Rack::Attack.cache.store.read(key).must_equal :struck_out
      end
    end
  end

  describe 'regular request when already struck out' do
    before {
      count_key = "rack::attack:#{Time.now.to_i/@period}:pentest:1.2.3.4"
      Rack::Attack.cache.store.write(count_key, 2)

      struck_out_key = "rack::attack:pentest:1.2.3.4"
      Rack::Attack.cache.store.write(struck_out_key, :struck_out)

      get '/foo/bar?hax=not_hacking', {}, 'REMOTE_ADDR' => '1.2.3.4' 
    }

    it "must not bump the strike_out count" do
      key = "rack::attack:#{Time.now.to_i/@period}:pentest:1.2.3.4"
      Rack::Attack.cache.store.read(key).must_equal 2
    end

    it "must report the match_type" do
      last_request.env['rack.attack.match_type'].must_equal :struck_out
    end

    it "must block the request" do
      last_response.status.must_equal 503
    end
  end
end
