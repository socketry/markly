# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "markly"

describe Markly::Node do
	let(:markdown) {"ruby:`Object.new`"}
	
	it "does not parse inline code info by default" do
		document = Markly.parse(markdown)
		expect(document.to_html).to be == "<p>ruby:<code>Object.new</code></p>\n"
	end
	
	with "inline code info enabled" do
		let(:document) {Markly.parse(markdown, flags: Markly::INLINE_CODE_INFO)}
		let(:code) {document.first_child.first_child}
		
		it "exposes the language on the code node" do
			expect(code.type).to be == :code
			expect(code.string_content).to be == "Object.new"
			expect(code.code_info).to be == "ruby"
			expect(code.code_language).to be == "ruby"
		end
		
		it "renders the language with both HTML renderers" do
			expect(document.to_html).to be == "<p><code class=\"language-ruby\">Object.new</code></p>\n"
			expect(Markly::Renderer::HTML.new.render(document)).to be == document.to_html
		end
		
		it "round-trips the language prefix" do
			expect(document.to_commonmark).to be == "ruby:`Object.new`\n"
		end
		
		it "can update and clear the language" do
			code.code_info = "c++"
			expect(code.code_info).to be == "c++"
			expect(document.to_html).to be == "<p><code class=\"language-c++\">Object.new</code></p>\n"
			
			code.code_info = nil
			expect(code.code_info).to be == ""
			expect(code.code_language).to be == nil
			expect(document.to_html).to be == "<p><code>Object.new</code></p>\n"
		end
		
		it "rejects invalid languages" do
			expect{code.code_info = "ruby lineno=5"}.to raise_exception(Markly::Error)
			expect(code.code_info).to be == "ruby"
		end
		
		it "keeps fence_info restricted to fenced nodes" do
			expect{code.fence_info}.to raise_exception(Markly::Error)
		end
	end
end
