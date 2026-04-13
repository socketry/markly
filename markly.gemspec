# frozen_string_literal: true

require_relative "lib/markly/version"

Gem::Specification.new do |spec|
	spec.name = "markly"
	spec.version = Markly::VERSION
	
	spec.summary = "CommonMark parser and renderer. Written in C, wrapped in Ruby."
	spec.authors = ["Garen Torikian", "Samuel Williams", "Yuki Izumi", "John MacFarlane", "Ashe Connor", "Nick Wellnhofer", "Brett Walker", "Andrew Anderson", "Ben Woosley", "Goro Fuji", "Olle Jonsson", "Peter H. Boling", "Tomoya Chiba", "Akira Matsuda", "Danny Iachini", "Henrik Nyh", "Jerry van Leeuwen", "Michael Camilleri", "Mu-An Chiou", "Roberto Hidalgo", "Ross Kaffenberger", "Vitaliy Klachkov"]
	spec.license = "MIT"
	
	spec.cert_chain  = ["release.cert"]
	spec.signing_key = File.expand_path("~/.gem/release.pem")
	
	spec.homepage = "https://github.com/socketry/markly"
	
	spec.metadata = {
		"documentation_uri" => "https://socketry.github.io/markly/",
		"funding_uri" => "https://github.com/sponsors/socketry/",
		"source_code_uri" => "https://github.com/socketry/markly.git",
	}
	
	spec.files = Dir.glob(["{context,ext,lib}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	spec.require_paths = ["lib"]
	
	spec.extensions = ["ext/markly/extconf.rb"]
	
	spec.required_ruby_version = ">= 3.3"
end
