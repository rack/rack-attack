# frozen_string_literal: true

module Rack
  class Attack
    # When using Rack::Attack with a Rails app, developers expect the request path
    # to be normalized. In particular, trailing slashes are stripped.
    # (See
    # https://github.com/rails/rails/blob/f8edd20/actionpack/lib/action_dispatch/journey/router/utils.rb#L5-L22
    # for implementation.)
    #
    # Look for an ActionDispatch utility class that Rails folks would expect
    # to normalize request paths. If unavailable, use a fallback class that
    # doesn't normalize the path (as a non-Rails rack app developer expects).

    module FallbackPathNormalizer
      def self.normalize_path(path)
        path
      end
    end

    PathNormalizer = if defined?(::ActionDispatch::Journey::Router::Utils)
                       # For Rails apps
                       ::ActionDispatch::Journey::Router::Utils
                     else
                       FallbackPathNormalizer
                     end
  end
end
