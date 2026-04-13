# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "markly"
require "markdown_spec"

MarkdownSpec.open("front_matter.txt").each do |testcase|
	# All examples in front_matter.txt are run with the FRONT_MATTER flag.
	flags = Markly::FRONT_MATTER
	extensions = testcase[:extensions]
	
	describe testcase[:section], unique: testcase[:example] do
		let(:document) {Markly.parse(testcase[:markdown], flags: flags, extensions: extensions)}
		
		it "produces the expected HTML output" do
			actual = document.to_html(flags: flags | Markly::UNSAFE, extensions: extensions).rstrip
			expect(actual).to be == testcase[:html]
		end
	end
end
