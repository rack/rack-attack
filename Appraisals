appraise "rack_2_0" do
  gem "rack", "~> 2.0.4"
end

appraise "rack_1_6" do
  gem "rack", "~> 1.6.9"

  # Override activesupport and actionpack version constraints by making
  # it more loose so it's compatible with rack 1.6.x
  gem "activesupport", ">= 4.2"
  gem "actionpack", ">= 4.2"

  # Override rack-test version constraint by making it more loose
  # so it's compatible with actionpack 4.2.x
  gem "rack-test", ">= 0.6"
end

appraise 'rails_5-2' do
  gem 'actionpack', '~> 5.2.0'
  gem 'activesupport', '~> 5.2.0'
end

appraise 'rails_5-1' do
  gem 'actionpack', '~> 5.1.0'
  gem 'activesupport', '~> 5.1.0'
end

appraise 'rails_4-2' do
  gem 'actionpack', '~> 4.2.0'
  gem 'activesupport', '~> 4.2.0'

  # Override rack-test version constraint by making it more loose
  # so it's compatible with actionpack 4.2.x
  gem "rack-test", ">= 0.6"
end

appraise 'dalli2' do
  gem 'dalli', '~> 2.0'
end

appraise "connection_pool_dalli" do
  gem "connection_pool", "~> 2.2"
  gem "dalli", "~> 2.7"
end

appraise "active_support_redis_cache_store" do
  gem "activesupport", "~> 5.2.0"
  gem "redis", "~> 4.0"
end

appraise "active_support_redis_cache_store_pooled" do
  gem "activesupport", "~> 5.2.0"
  gem "connection_pool", "~> 2.2"
  gem "redis", "~> 4.0"
end

appraise "redis_store" do
  gem "redis-store", "~> 1.5"
end

appraise "active_support_redis_store" do
  gem "redis-activesupport", "~> 5.0"
end
