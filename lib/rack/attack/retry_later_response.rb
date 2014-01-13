module Rack
  module Attack
    class RetryLaterResponse
      def [](env)
        retry_after = env['rack.attack.match_data'][:period] rescue nil
        [429, {'Retry-After' => retry_after.to_s}, ["Retry later\n"]]
      end
    end
  end
end
