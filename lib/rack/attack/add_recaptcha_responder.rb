module Rack
  module Attack
    class AddRecaptchaResponder
      def initialize(app)
        @app = app
      end

      def [](env)
        env["rack.attack.use_recaptcha"] = true
        @app.call(env)
      end
    end
  end
end
