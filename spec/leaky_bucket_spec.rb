require_relative "spec_helper"
require "active_support/core_ext/numeric/time"

describe "Rack::Attack::LeakyBucket" do
  describe ".new(1, 1, Time.now, 0), empty bucket" do
    it "isn't full" do
      bucket = Rack::Attack::LeakyBucket.new(1, 1, Time.now, 0)
      assert !bucket.full?, "Empty bucket reports as full"
    end

    it "becomes full when 1 is added" do
      bucket = Rack::Attack::LeakyBucket.new(1, 1, Time.now, 0)
      bucket.add(1)
      assert bucket.full?, "Bucket that has value set to it's capacity should be full"
    end
  end

  describe ".new(1, 1, Time.now, 1), full bucket" do
    it "reports seconds_to_drain as 1" do
      Time.stub :now, Time.now do
        bucket = Rack::Attack::LeakyBucket.new(1, 1, Time.now, 1)
        assert bucket.seconds_until_drained == 1.0
      end
    end

    it "becomes empty after 1 second" do
      bucket = Rack::Attack::LeakyBucket.new(1, 1, Time.now, 1)
      Time.stub :now, 1.second.from_now do
        assert !bucket.full?, "Bucket wasn't empty, instead had value = #{bucket.value}"
        assert bucket.seconds_until_drained == 0, "Bucket reports seconds_until_drained = #{bucket.seconds_until_drained}"
      end
    end
  end

  describe ".unserialize" do
    it "unserializes raw data correctly" do
      Time.stub :now, Time.now do
        bucket = Rack::Attack::LeakyBucket.unserialize("1|#{Time.now.to_f}", 1, 1)
        assert_equal bucket.value, 1
        assert_equal bucket.last_updated_at, Time.now.to_f
        assert_equal bucket.leak, 1
        assert_equal bucket.capacity, 1
        assert bucket.full?, "Bucket isn't full"
      end
    end

    it "handles nils correctly" do
      Time.stub :now, Time.now do
        bucket = Rack::Attack::LeakyBucket.unserialize(nil, 1, 1)
        assert_equal bucket.value, 0
        assert_equal bucket.last_updated_at, Time.now.to_f
        assert_equal bucket.leak, 1
        assert_equal bucket.capacity, 1
        assert !bucket.full?
      end
    end

    it "handles wrong values correctly" do
      Time.stub :now, Time.now do
        bucket = Rack::Attack::LeakyBucket.unserialize("-1|-132", 1, 1)
        assert_equal bucket.value, 0
        assert_equal bucket.last_updated_at, Time.now.to_f
        assert_equal bucket.leak, 1
        assert_equal bucket.capacity, 1
        assert !bucket.full?
      end
    end
  end
end
