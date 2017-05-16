# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'utils/version'

Gem::Specification.new do |spec|
  spec.name          = "utils-rb"
  spec.version       = Utils::VERSION
  spec.authors       = ["Xuhao"]
  spec.email         = ["hao.xu@quadas.com"]

  spec.summary       = %q{A collection of ruby utility libraries used by other frontend projects}
  spec.description   = %q{A collection of ruby utility libraries used by other frontend projects}
  spec.homepage      = "https://github.com/quadas/utils-rb"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activesupport', '~> 4.1'
  spec.add_dependency 'activerecord', '~> 4.1'
  spec.add_dependency 'sqlite3'
  spec.add_dependency 'faraday'
  spec.add_dependency 'exception_notification'
  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
