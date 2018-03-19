require_relative "../spec_helper"

describe "Cache store config when using allow2ban" do
  before do
    Rack::Attack.blocklist("allow2ban pentesters") do |request|
      Rack::Attack::Allow2Ban.filter(request.ip, maxretry: 2, findtime: 30, bantime: 60) do
        request.path.include?("scarce-resource")
      end
    end
  end

  it "gives error if no store was configured" do
    assert_raises do
      get "/"
    end
  end

  it "gives error if incompatible store was configured" do
    Rack::Attack.cache.store = Object.new

    assert_raises do
      get "/"
    end
  end

  it "works with any object that responds to #read, #write and #increment" do
    basic_store_class = Class.new do
      attr_accessor :backend

      def initialize
        @backend = {}
      end

      def read(key)
        @backend[key]
      end

      def write(key, value, options = {})
        @backend[key] = value
      end

      def increment(key, count, options = {})
        @backend[key] ||= 0
        @backend[key] += 1
      end
    end

    Rack::Attack.cache.store = basic_store_class.new

    get "/"
    assert_equal 200, last_response.status

    get "/scarce-resource"
    assert_equal 200, last_response.status

    get "/scarce-resource"
    assert_equal 200, last_response.status

    get "/scarce-resource"
    assert_equal 403, last_response.status

    get "/"
    assert_equal 403, last_response.status
  end
end
