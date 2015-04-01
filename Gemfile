source 'https://rubygems.org'
gemspec development_group: :gem_build_tools

group :development do
  gem 'benchmark_suite'
  gem 'guard-rspec'
  gem 'rb-fsevent', '~> 0.9.1' if RUBY_PLATFORM =~ /darwin/
end

group :test do
  gem 'rspec', '~> 2.14.0'
end

group :gem_build_tools do
  gem 'rake'
end

gem 'coveralls', require: false
gem 'celluloid', github: 'celluloid/celluloid', branch: 'master'
