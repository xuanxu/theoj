# frozen_string_literal: true

require File.expand_path "#{File.dirname(__FILE__)}/lib/theoj/version"

Gem::Specification.new do |s|
  s.name = "theoj"
  s.version = Theoj::VERSION
  s.platform = Gem::Platform::RUBY
  s.date = Time.now.strftime('%Y-%m-%d')
  s.authors = ["Juanjo Bazán"]
  s.homepage = 'http://github.com/xuanxu/theoj'
  s.license = "MIT"
  s.summary = "Editorial objects used by the Open Journals"
  s.description = "A library to manage editorial objects used in the Open Journals' review process"
  s.metadata = {
    "bug_tracker_uri"   => "https://github.com/xuanxu/theoj/issues",
    "changelog_uri"     => "https://github.com/xuanxu/theoj/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://www.rubydoc.info/gems/theoj",
    "homepage_uri"      => s.homepage,
    "source_code_uri"   => s.homepage
  }
  s.files = %w(LICENSE README.md CHANGELOG.md) + Dir.glob("{spec,lib/**/*}") & `git ls-files -z`.split("\0")
  s.require_paths = ["lib"]
  s.rdoc_options = ['--main', 'README.md', '--charset=UTF-8']

  s.add_dependency "octokit", "~> 5.6.1"
  s.add_dependency "faraday", "~> 2.5.2"
  s.add_dependency "openjournals-nameable", "~> 1.1"
  s.add_dependency "github-linguist", "~> 7.23.0"
  s.add_dependency "rugged", "~> 1.5.0"

  s.add_development_dependency "rake", "~> 13.0.6"
  s.add_development_dependency "rspec", "~> 3.11"
end
