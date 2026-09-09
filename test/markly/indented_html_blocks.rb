# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "markly"

describe Markly::INDENTED_HTML_BLOCKS do
	let(:flags) {Markly::INDENTED_HTML_BLOCKS}
	
	it "preserves CommonMark behavior by default" do
		markdown = "<div>\n\t<p>one</p>\n\n\t<p>two</p>\n</div>\n"
		document = Markly.parse(markdown)
		
		expect(document.first_child.type).to be == :html
		expect(document.first_child.next).not.to be_nil
	end
	
	it "keeps consistently indented HTML together across blank lines" do
		markdown = "<div>\n\t<p>one</p>\n\n    <p>two</p>\n</div>\n"
		document = Markly.parse(markdown, flags: flags)
		
		expect(document.first_child.type).to be == :html
		expect(document.first_child.string_content).to be == markdown
		expect(document.first_child.next).to be_nil
	end
	
	it "can establish indentation after an initial blank line" do
		markdown = "<div>\n\n\t<p>content</p>\n</div>\n"
		document = Markly.parse(markdown, flags: flags)
		
		expect(document.first_child.string_content).to be == markdown
		expect(document.first_child.next).to be_nil
	end
	
	it "ends the HTML block when content dedents after a blank line" do
		markdown = "<div>\n\tcontent\n\noutside\n"
		document = Markly.parse(markdown, flags: flags)
		
		expect(document.first_child.string_content).to be == "<div>\n\tcontent\n\n"
		expect(document.first_child.next.type).to be == :paragraph
	end
	
	it "does not extend unindented HTML content" do
		markdown = "<div>\ncontent\n\nmore\n"
		document = Markly.parse(markdown, flags: flags)
		
		expect(document.first_child.next).not.to be_nil
	end
	
	it "renders retained raw HTML when unsafe rendering is enabled" do
		markdown = "<slide-diagram>\n  first\n\n    nested\n</slide-diagram>\n"
		html = Markly.render_html(
			markdown,
			parse_flags: flags,
			render_flags: Markly::UNSAFE,
		)
		
		expect(html).to be == markdown
	end
end
