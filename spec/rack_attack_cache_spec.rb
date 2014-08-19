require_relative 'spec_helper'

describe Rack::Attack::Cache do
  describe "#count" do
    before do
      @cache = Rack::Attack::Cache.new
      @store = MiniTest::Mock.new
      @cache.store = @store
    end
    describe "with a integer period" do
      it "should set key with using current time over period" do
        Time.stub(:now, 30) do
          @store.expect(:increment, true, ["rack::attack:1:cache-test-key", 1, {expires_in: 20}])
          @cache.count("cache-test-key", 25)
        end
      end
    end
    describe "with a range period" do
      it "should set key with using current time over period" do
        Time.stub(:now, 6) do
          @store.expect(:increment, true, ["rack::attack:5..10:cache-test-key", 1, {expires_in: 4}])
          @cache.count("cache-test-key", (5..10))
        end
      end
    end
  end
end
