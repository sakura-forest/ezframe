
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ezframe/version"

Gem::Specification.new do |spec|
  spec.name          = "ezframe"
  spec.version       = Ezframe::VERSION
  spec.authors       = ["KAMACHI Masayuki"]
  spec.email         = ["kamachi@sakuraforest.co.jp"]

  spec.summary       = %q{simple and easy-to-use web framework}
  spec.description   = %q{easy web framework}
  spec.homepage      = "https://github.com/sakura-forest/ezframe"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  #if spec.respond_to?(:metadata)
  #  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  #else
  #  raise "RubyGems 2.0 or newer is required to protect against " \
  #    "public gem pushes."
  #end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", '~> 5.13.0'
  spec.add_development_dependency "nokogiri", '~> 1.10.7'
  spec.add_development_dependency "rubocop", '~> 0.77.0'

  spec.add_runtime_dependency 'rack', '~> 2.0.7'
  spec.add_runtime_dependency 'sequel', '~> 5.27.0'
  spec.add_runtime_dependency 'sqlite3', '~> 1.4.0'
  spec.add_runtime_dependency 'htmlbeautifier', '~> 1.3.1'
  spec.add_runtime_dependency 'ruby2js', '~> 3.2.0'
end
