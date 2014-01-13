require_relative "spec_helper"

describe "Rack::Attack::AddRecaptchaResponse" do
  it "calls the app with a flag to use recaptcha" do
    app = MiniTest::Mock.new
    app.expect(:call, nil, [{"rack.attack.use_recaptcha" => true}])

    Rack::Attack::AddRecaptchaResponder.new(app)[{}]

    app.verify
  end

  it "returns the app's response" do
    app = lambda { |env| "response" }

    responder = Rack::Attack::AddRecaptchaResponder.new(app)

    responder[{}].must_equal "response"
  end
end
