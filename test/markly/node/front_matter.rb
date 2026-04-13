# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "markly"

describe Markly::Node do
	let(:flags) {Markly::FRONT_MATTER}
	
	with "front matter with info string" do
		let(:input) {"--- yaml\ntitle: Hello\n---\n# Body\n"}
		let(:document) {Markly.parse(input, flags: flags)}
		
		it "exposes the info string via fence_info" do
			expect(document.first_child.fence_info).to be == "yaml"
		end
		
		it "stores the raw content separately from the info string" do
			expect(document.first_child.string_content).to be == "title: Hello\n"
		end
		
		it "round-trips the info string in commonmark output" do
			expect(document.first_child.to_commonmark).to be =~ /^--- yaml/
		end
	end
	
	with "valid front matter closed by ---" do
		let(:input) {"---\ntitle: Hello\nauthor: Alice\n---\n# Body\n"}
		let(:document) {Markly.parse(input, flags: flags)}
		
		it "does not appear in plain text output" do
			expect(document.to_plaintext).not.to be =~ /title: Hello/
		end
		
		it "produces a front_matter node as the first child" do
			expect(document.first_child.type).to be == :front_matter
		end
		
		it "stores the raw content without delimiter lines" do
			expect(document.first_child.string_content).to be == "title: Hello\nauthor: Alice\n"
		end
		
		it "continues parsing the remaining markdown" do
			expect(document.first_child.next.type).to be == :header
		end
		
		it "renders HTML without including the front matter" do
			html = document.to_html
			expect(html).to be =~ /<h1>/
			expect(html).not.to be =~ /---/
			expect(html).not.to be =~ /title: Hello/
		end
	end
	
	with "four dashes on line 1 is a thematic break, not front matter" do
		let(:input) {"----\ntitle: Hello\n---\n# Body\n"}
		let(:document) {Markly.parse(input, flags: flags)}
		
		it "does not produce a front_matter node" do
			expect(document.first_child.type).not.to be == :front_matter
		end
	end
	
	with "front matter where ... appears in content" do
		let(:input) {"---\ntitle: Hello\n...\n---\n# Body\n"}
		let(:document) {Markly.parse(input, flags: flags)}
		
		it "treats ... as content, not a closing delimiter" do
			expect(document.first_child.type).to be == :front_matter
			expect(document.first_child.string_content).to be == "title: Hello\n...\n"
		end
	end
	
	with "front matter only (no body)" do
		let(:input) {"---\ntitle: Hello\n---\n"}
		let(:document) {Markly.parse(input, flags: flags)}
		
		it "produces only the front_matter node" do
			expect(document.first_child.type).to be == :front_matter
			expect(document.first_child.next).to be == nil
		end
	end
	
	with "empty front matter" do
		let(:input) {"---\n---\n# Body\n"}
		let(:document) {Markly.parse(input, flags: flags)}
		
		it "produces an empty front_matter node" do
			expect(document.first_child.type).to be == :front_matter
			expect(document.first_child.string_content).to be == ""
		end
	end
	
	with "no closing delimiter" do
		let(:input) {"---\ntitle: Hello\n# Body\n"}
		let(:document) {Markly.parse(input, flags: flags)}
		
		it "treats the entire document as front matter" do
			expect(document.first_child.type).to be == :front_matter
		end
		
		it "accumulates all content after the opening delimiter" do
			expect(document.first_child.string_content).to be == "title: Hello\n# Body\n"
		end
		
		it "produces no other nodes" do
			expect(document.first_child.next).to be == nil
		end
	end
	
	with "document not starting with ---" do
		let(:input) {"# Just a heading\n---\ntitle: Not front matter\n---\n"}
		let(:document) {Markly.parse(input, flags: flags)}
		
		it "does not produce a front_matter node" do
			expect(document.first_child.type).not.to be == :front_matter
		end
	end
	
	with "flag not set" do
		let(:input) {"---\ntitle: Hello\n---\n# Body\n"}
		let(:document) {Markly.parse(input)}
		
		it "does not produce a front_matter node" do
			expect(document.first_child.type).not.to be == :front_matter
		end
	end
end
