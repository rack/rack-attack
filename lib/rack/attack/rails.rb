module Rack
  module Attack
    module RecaptchaClientHelper
      def recaptcha_tags_if_under_attack(options = {})
        recaptcha_tags(options) if request.env["rack.attack.use_recaptcha"]
      end
    end

    module RecaptchaVerify
      def verify_recaptcha_if_under_attack(options = {})
        if request.env["rack.attack.use_recaptcha"]
          verify_recaptcha(options)
        else
          true
        end
      end
    end
  end
end

ActionView::Base.send(:include, Rack::Attack::RecaptchaClientHelper)
ActionController::Base.send(:include, Rack::Attack::RecaptchaVerify)
