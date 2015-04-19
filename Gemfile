source 'https://rubygems.org'
gemspec development_group: :gem_build_tools

group :development do
  gem 'benchmark_suite'
  gem 'guard-rspec'
  gem 'rb-fsevent', '~> 0.9.1' if RUBY_PLATFORM =~ /darwin/
end

group :test do
  gem 'rspec', '~> 3.2'
  gem 'nenv'
end

group :gem_build_tools do
  gem 'rake'
end

gem 'coveralls', require: false

gem 'celluloid',             github: 'celluloid/celluloid',             branch: '0.17.0-prerelease'

# folowwing should be removed as soon as celluloid marks them as runtime dependencies
gem 'celluloid-pool',        github: 'celluloid/celluloid-pool',        branch: 'master'
gem 'celluloid-fsm',         github: 'celluloid/celluloid-fsm',         branch: 'master'
gem 'celluloid-supervision', github: 'celluloid/celluloid-supervision', branch: 'master'
