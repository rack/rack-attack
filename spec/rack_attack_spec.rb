require_relative 'spec_helper'

describe 'Rack::Attack' do
  include Rack::Test::Methods

  before do
    Rack::Attack.block("ip 1.2.3.4") {|req| req.ip == '1.2.3.4' }
  end

  def app
    Rack::Builder.new {
      use Rack::Attack
      run lambda {|env| [200, {}, ['Hello World']]}
    }.to_app
  end

  it 'has a block' do
    Rack::Attack.blocks.class.must_equal Hash
  end

  it "says hello" do
    get '/'
    last_response.status.must_equal 200
    last_response.body.must_equal 'Hello World'
  end


end
