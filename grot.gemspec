# frozen_string_literal: true

require_relative "lib/grot/version"

Gem::Specification.new do |spec|
  spec.name = "grot"
  spec.version = Grot::VERSION

  spec.authors = "fungus-wine"

  spec.summary = "Arduino command-line development tool"
  spec.description = "Grot is a command-line tool that simplifies Arduino development with arduino-cli."
  spec.homepage = "https://github.com/fungus-wine/grot"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata = {
    "source_code_uri" => "https://github.com/fungus-wine/grot",
    "changelog_uri" => "https://github.com/fungus-wine/blob/main/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.glob("{bin,lib}/**/*") + %w[LICENSE.md README.md CHANGELOG.md]
  spec.bindir = "exe"
  spec.executables = ["grot"]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "rubyserial", "~> 0.6"
  spec.add_dependency "toml-rb", "~> 2.2"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
end