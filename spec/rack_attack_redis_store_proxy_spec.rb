require_relative 'spec_helper'

describe Rack::Attack::StoreProxy::RedisStoreProxy do

  it 'should stub Redis::Store#with on older clients' do
    proxy = Rack::Attack::StoreProxy::RedisStoreProxy.new(Class.new)
    proxy.with {} # will not raise an error
  end

end
