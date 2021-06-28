source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in promoted-ruby-client.gemspec
gemspec

gem 'faraday', '~> 1.4.1'
gem 'faraday_middleware'
gem 'faraday-net_http'
gem 'concurrent-ruby', require: 'concurrent'

group :development do
    gem 'ruby-debug-ide', group: :development
    gem 'debase', '>= 0.2.5.beta2', group: :development
    gem 'jaro_winkler', group: :development
    gem 'solargraph', group: :development
end

gem 'simplecov', require: false, group: :test