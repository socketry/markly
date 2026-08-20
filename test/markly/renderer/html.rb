# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2019, by Garen Torikian.
# Copyright, 2020-2025, by Samuel Williams.

require "markly"

describe Markly::Renderer::HTML do
	let(:markdown) {"# Introduction\nHi *there*"}
	let(:document) {Markly.parse(markdown)}
	let(:renderer) {subject.new}
	
	it "can render HTML" do
		expect(renderer.render(document)).to be == "<h1>Introduction</h1>\n<p>Hi <em>there</em></p>\n"
	end
	
	with "ids" do
		let(:renderer) {subject.new(ids: true)}
		
		it "can render HTML with ids" do
			expect(renderer.render(document)).to be == "<section id=\"introduction\"><h1>Introduction</h1>\n<p>Hi <em>there</em></p>\n</section>"
		end
		
		it "generates unique IDs for duplicate headings" do
			markdown = <<~MARKDOWN
				## Deployment
				
				Content about first deployment.
				
				## Deployment
				
				Content about second deployment.
				
				## Deployment
				
				Content about third deployment.
			MARKDOWN
			
			doc = Markly.parse(markdown)
			html = renderer.render(doc)
			
			expect(html).to be(:include?, '<section id="deployment">')
			expect(html).to be(:include?, '<section id="deployment-2">')
			expect(html).to be(:include?, '<section id="deployment-3">')
		end
	end
	
	with ".anchor_for" do
		let(:markdown) {<<~MARKDOWN}
			# Hello World
			
			## Test *Emphasis* & **Bold**
			
			### Special!@# Characters"}
		MARKDOWN
		
		let(:document) {Markly.parse(markdown)}
		
		it "can generate URL-safe anchors from headers" do
			headers = document.to_a.select{|node| node.type == :header}
			
			expect(subject.anchor_for(headers[0])).to be == "hello-world"
			expect(subject.anchor_for(headers[1])).to be == "test-emphasis-&-bold"
			expect(subject.anchor_for(headers[2])).to be == "special!@#-characters\"}"
		end
		
		it "works as a class method" do
			header = document.first_child
			expect(Markly::Renderer::HTML.anchor_for(header)).to be == "hello-world"
		end
		
		it "works as an instance method" do
			header = document.first_child
			expect(renderer.anchor_for(header)).to be == "hello-world"
		end
		
		it "handles edge cases properly" do
			test_cases = [
				["# Multiple    Spaces", "multiple-spaces"],
				["## !@#$%^&*()", "!@#$%^&*()"],
				["### Leading-and-trailing---hyphens-", "leading-and-trailing---hyphens-"],
				["#### Unicode: Café & Résumé", "unicode:-café-&-résumé"]
			]
			
			test_cases.each do |markdown, expected|
				doc = Markly.parse(markdown)
				header = doc.first_child
				expect(subject.anchor_for(header)).to be == expected
			end
		end
		
		it "removes leading and trailing hyphens" do
			test_cases = [
				["# ---Leading Hyphens", "---leading-hyphens"],
				["## Trailing Hyphens---", "trailing-hyphens---"],
				["### ---Both Leading and Trailing---", "---both-leading-and-trailing---"],
				["#### Multiple   ---   Spaces   ---   Between", "multiple-----spaces-----between"],
				["##### (Special) Characters!@# Create Hyphens", "(special)-characters!@#-create-hyphens"]
			]
			
			test_cases.each do |markdown, expected|
				doc = Markly.parse(markdown)
				header = doc.first_child
				expect(subject.anchor_for(header)).to be == expected
			end
		end
		
		it "preserves periods, colons, and hash symbols in anchors" do
			test_cases = [
				["# Version 1.0 Release", "version-1.0-release"],
				["## Method .call() Usage", "method-.call()-usage"],
				["### File.txt Processing", "file.txt-processing"],
				["#### API v2.5.1 Documentation", "api-v2.5.1-documentation"],
				["##### Dr. Smith's Research", "dr.-smith's-research"]
			]
			
			test_cases.each do |markdown, expected|
				doc = Markly.parse(markdown)
				header = doc.first_child
				expect(subject.anchor_for(header)).to be == expected
			end
		end
	end
	
	with "multiple tables" do
		let(:markdown) do
			<<~MARKDOWN
				| Input       | Expected         | Actual    |
				| ----------- | ---------------- | --------- |
				| One         | Two              | Three     |
				
				| Header   | Row  | Example |
				| :------: | ---: | :------ |
				| Foo      | Bar  | Baz     |
			MARKDOWN
		end
		let(:document) {Markly.parse(markdown, extensions: %i[autolink table tagfilter])}
		
		it "can render multiple tables" do
			expect(renderer.render(document).scan(/<tbody>/).size).to be == 2
		end
		
		it "generates the same output as the built in renderer" do
			expect(renderer.render(document)).to be == document.to_html
		end
	end
	
	with "footnotes" do
		let(:markdown) {"Hello[^hi].\n\n[^hi]: Hey!\n"}
		let(:document) {Markly.parse(markdown, flags: Markly::FOOTNOTES)}
		
		it "can render footnotes" do
			expect(renderer.render(document)).to be == <<~HTML
				<p>Hello<sup class="footnote-ref"><a href="#fn-hi" id="fnref-hi" data-footnote-ref>1</a></sup>.</p>
				<section class="footnotes" data-footnotes>
				<ol>
				<li id="fn-hi">
				<p>Hey! <a href="#fnref-hi" class="footnote-backref" data-footnote-backref data-footnote-backref-idx="1" aria-label="Back to reference 1">↩</a></p>
				</li>
				</ol>
				</section>
			HTML
		end
		
		it "generates the same output as the built in renderer" do
			expect(renderer.render(document)).to be == document.to_html
		end
	end
	
	with "render flags" do
		it "renders fenced code languages on the pre element" do
			document = Markly.parse("```ruby\nputs 'Hello'\n```")
			renderer = subject.new(flags: Markly::GITHUB_PRE_LANG)
			
			expect(renderer.render(document)).to be == "<pre lang=\"ruby\"><code>puts 'Hello'\n</code></pre>\n"
		end
		
		it "omits unsafe block HTML" do
			document = Markly.parse("<div>Unsafe</div>")
			
			expect(renderer.render(document)).to be == "<!-- raw HTML omitted -->\n"
		end
		
		it "omits unsafe inline HTML" do
			document = Markly.parse("Before <span>unsafe</span> after")
			
			expect(renderer.render(document)).to be == "<p>Before <!-- raw HTML omitted -->unsafe<!-- raw HTML omitted --> after</p>\n"
		end
		
		it "renders soft breaks as hard breaks" do
			document = Markly.parse("One\nTwo")
			renderer = subject.new(flags: Markly::HARD_BREAKS)
			
			expect(renderer.render(document)).to be == "<p>One<br />\nTwo</p>\n"
		end
		
		it "renders soft breaks as spaces" do
			document = Markly.parse("One\nTwo")
			renderer = subject.new(flags: Markly::NO_BREAKS)
			
			expect(renderer.render(document)).to be == "<p>One Two</p>\n"
		end
	end
end
