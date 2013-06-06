module Rack
  module Attack
    class StrikeOut
      MANDATORY_OPTIONS = [:limit, :period]
      attr_reader :name, :limit, :period, :block
      def initialize(name, options, block)
        @name, @block = name, block
        MANDATORY_OPTIONS.each do |opt|
          raise ArgumentError.new("Must pass #{opt.inspect} option") unless options[opt]
        end
        @limit  = options[:limit]
        @period = options[:period].to_i
      end

      def cache
        Rack::Attack.cache
      end

      def [](req)
        umpire = Umpire.new
        # instance_eval on umpire to get the `strike!` DSL method defined in called block
        discriminator = umpire.instance_exec(req, &block)
        return false unless discriminator

        key = "#{name}:#{discriminator}"
        
        struck_out = cache.read(key)
        strike = umpire.strike?

        unless struck_out || strike
          # all ok - falsey value means not struck out
          false
        else
          if strike
            count = cache.count(key, period)
            if count && count > limit
              cache.write(key, :struck_out, period)
            end
            
            req.env['rack.attack.match_type'] = :strike
            data = {
              :count => count,
              :period => period,
              :limit => limit,
              :struck_out => struck_out
            }
            (req.env['rack.attack.match_data'] ||= {})[name] = data
          elsif struck_out
            req.env['rack.attack.match_type'] = :struck_out
          end

          req.env['rack.attack.matched'] = name
          Rack::Attack.instrument(req)
          true
        end
      end
      
      class Umpire
        def strike!
          @strike = true
        end
        
        def strike?
          @strike
        end
      end

    end
  end
end
