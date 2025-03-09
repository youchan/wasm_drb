# frozen_string_literal: true

require_relative "lib/wasm_drb/version"

Gem::Specification.new do |spec|
  spec.name = "wasm_drb"
  spec.version = Wasm::Drb::VERSION
  spec.authors = ["youchan"]
  spec.email = ["youchan01@gmail.com"]

  spec.summary = "A dRuby implementation for ruby.wasm."
  spec.description = "A dRuby implementation for ruby.wasm."
  spec.homepage = "https://github.com/youchan/wasm_drb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/youchan/wasm_drb"
  spec.metadata["changelog_uri"] = "https://github.com/youchan/wasm_drb/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[examples/ bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "ruby_wasm", "~> 2.7"
  spec.add_dependency "js", "~> 2.7"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
