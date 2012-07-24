require_relative 'spec_helper'

describe 'Rack::Attack' do
  include Rack::Test::Methods

  def app
    Rack::Builder.new {
      use Rack::Attack
      run lambda {|env| [200, {}, ['Hello World']]}
    }.to_app
  end

  it "says hello" do
    get '/'
    last_response.status.must_equal 200
    last_response.body.must_equal 'Hello World'
  end
end
