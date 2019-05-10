# frozen_string_literal: true

module Rack
  class Attack
    class Track
      attr_reader :filter

      def initialize(name, options = {}, &block)
        options[:type] = :track

        if options[:limit] && options[:period]
          @filter = Throttle.new(name, options, &block)
        else
          @filter = Check.new(name, options, &block)
        end
      end

      def matched_by?(request)
        filter.matched_by?(request)
      end
    end
  end
end
