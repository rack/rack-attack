# frozen_string_literal: true

appraise "rack_3" do
  gem "rack", "~> 3.0"
end

appraise "rack_2" do
  gem "rack", "~> 2.0"
end

appraise "rack_1" do
  # Override activesupport and actionpack version constraints by making
  # it more loose so it's compatible with rack 1.6.x
  gem "actionpack", ">= 4.2"
  gem "activesupport", ">= 4.2"

  gem "rack", "~> 1.6"

  # Override rack-test version constraint by making it more loose
  # so it's compatible with actionpack 4.2.x
  gem "rack-test", ">= 0.6"
end

appraise 'rails_7-1' do
  gem 'railties', '~> 7.1.0'
end

appraise 'rails_7-0' do
  gem 'railties', '~> 7.0.0'
end

appraise 'rails_6-1' do
  gem 'railties', '~> 6.1.0'
end

appraise 'rails_6-0' do
  gem 'railties', '~> 6.0.0'
end

appraise 'rails_5-2' do
  gem 'railties', '~> 5.2.0'
end

appraise 'rails_4-2' do
  gem 'railties', '~> 4.2.0'

  # Override rack-test version constraint by making it more loose
  # so it's compatible with actionpack 4.2.x
  gem "rack-test", ">= 0.6"
end

appraise 'dalli2' do
  gem 'dalli', '~> 2.0'
end

appraise 'dalli3' do
  gem 'dalli', '~> 3.0'
end

appraise 'redis_5' do
  gem 'redis', '~> 5.0'
end

appraise 'redis_4' do
  gem 'redis', '~> 4.0'
end

appraise "connection_pool_dalli" do
  gem "connection_pool", "~> 2.2"
  gem "dalli", "~> 3.0"
end

appraise "active_support_redis_cache_store" do
  gem "activesupport", "~> 6.1.0"
  gem "redis", "~> 5.0"
end

appraise "active_support_redis_cache_store_pooled" do
  gem "activesupport", "~> 6.1.0"
  gem "connection_pool", "~> 2.2"
  gem "redis", "~> 5.0"
end

appraise "active_support_5_redis_cache_store" do
  gem "activesupport", "~> 5.2.0"
  gem "redis", "~> 5.0"
end

appraise "active_support_5_redis_cache_store_pooled" do
  gem "activesupport", "~> 5.2.0"
  gem "connection_pool", "~> 2.2"
  gem "redis", "~> 5.0"
end

appraise "redis_store" do
  gem "redis-store", "~> 1.5"
end
