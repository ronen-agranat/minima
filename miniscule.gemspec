# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "miniscule"
  spec.version       = "0.1.4"
  spec.authors       = ["Ronen Agranat"]
  spec.email         = ["ronen.agranat@gmail.com"]

  spec.summary       = "A slightly more beautiful, slightly less minimal theme for Jekyll."
  spec.homepage      = "https://github.com/ronen-agranat/miniscule"
  spec.license       = "MIT"

  spec.metadata["plugin_type"] = "theme"

  spec.files = `git ls-files -z`.split("\x0").select do |f|
    f.match(%r!^(assets|_(includes|layouts|sass)/|(LICENSE|README)((\.(txt|md|markdown)|$)))!i)
  end

  spec.add_runtime_dependency "jekyll", "~> 3.5"
  spec.add_runtime_dependency "jekyll-feed", "~> 0.9"
  spec.add_runtime_dependency "jekyll-seo-tag", "~> 2.1"
  spec.add_development_dependency "bundler", "~> 1.15"
end
