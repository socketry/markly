# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017, by Yuki Izumi.
# Copyright, 2019, by Garen Torikian.
# Copyright, 2020-2025, by Samuel Williams.

require "markly"

MARKDOWN = <<~MD
Hi *there*!

1. I am a numeric list.
2. I continue the list.
* Suddenly, an unordered list!
* What fun!

Okay, _enough_.

| a   | b   |
| --- | --- |
| c   | d   |
MD

PLAINTEXT = <<~PLAINTEXT
Hi there!

1.  I am a numeric list.
2.  I continue the list.

  - Suddenly, an unordered list!
  - What fun!

Okay, enough.

| a | b |
| --- | --- |
| c | d |
PLAINTEXT

describe Markly do
	let(:document) {Markly.parse(MARKDOWN, extensions: %i[table])}
	
	it "can generate plaintext" do
		expect(document.to_plaintext).to be == PLAINTEXT
	end
	
	with "text the renderer copies in runs" do
		it "wraps at the width inside a list item" do
			document = Markly.parse("- Alice keeps the radio-manual-v2.pdf in a drawer next to the old radio.")
			
			expect(document.to_plaintext(width: 20)).to be == "  - Alice keeps the\n    radio-manual-v2.pdf\n    in a drawer next\n    to the old\n    radio.\n"
		end
		
		it "keeps multibyte characters intact" do
			document = Markly.parse("> Déjà vu: l'été à Zürich 日本 😀")
			
			expect(document.to_plaintext).to be == "Déjà vu: l'été à Zürich 日本 😀\n"
		end
		
		it "indents every line of a code block in a list item" do
			document = Markly.parse("1. item\n\n   ```\n   code line one\n   code line two\n   ```")
			
			expect(document.to_plaintext).to be == "1.  item\n    \n    code line one\n    code line two\n"
		end
		
		it "stops at invalid UTF-8 in a text node built through the API" do
			document = Markly.parse("- item")
			text = Markly::Node.new(:text)
			text.string_content = "valid \xFF lost".b.force_encoding(Encoding::UTF_8)
			document.first_child.first_child.first_child.append_child(text)
			
			expect(document.to_plaintext).to be == "  - itemvalid \n"
		end
		
		it "writes U+FFFE and U+FFFF as cmark's encoder does" do
			document = Markly.parse("a\u{FFFE}b \u{FFFF}c")
			
			expect(document.to_plaintext).to be == "a\xFEb \xFFc\n"
		end
	end
end
