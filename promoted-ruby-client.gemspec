
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "promoted/ruby/client/version"

Gem::Specification.new do |spec|
  spec.name          = "promoted-ruby-client"
  spec.version       = Promoted::Ruby::Client::VERSION
  spec.authors       = ["scottmcmaster"]
  spec.email         = ["scott@promoted.ai"]

  spec.summary       = 'A Ruby Client to contact Promoted APIs.'
  spec.description   = 'This is primarily intended to be used when logging Requests and Insertions on a backend server.'
  spec.homepage      = 'https://github.com/promotedai/promoted-ruby-client'
  spec.license       = 'MIT'

  # Uncomment if you want to push to a custom host
  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/promotedai/promoted-ruby-client"
  spec.metadata["changelog_uri"] = "https://github.com/promotedai/promoted-ruby-client/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.extra_rdoc_files = ['README.md']
  spec.bindir           = "exe"
  spec.executables      = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths    = ["lib"]

  spec.add_runtime_dependency 'faraday', '>= 0.9.0'
  spec.add_runtime_dependency 'faraday_middleware', '>= 0.9.0'
  spec.add_runtime_dependency 'net-http-persistent', '~> 4.0'
  spec.add_runtime_dependency 'concurrent-ruby', '~> 1'

  spec.add_development_dependency "bundler", '~> 2.2', '>= 2.2.24'
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
