appraise "rack_2_0" do
  gem "rack", "~> 2.0.4"
end

appraise "rack_1_6" do
  gem "rack", "~> 1.6.9"

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
