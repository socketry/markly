# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "markly"

describe Markly::Renderer::Generic do
	let(:renderer_class) do
		Class.new(subject) do
			def text(node)
				out(node.string_content)
			end
			
			def output
				@stream.string
			end
		end
	end
	
	let(:renderer) {renderer_class.new}
	
	with "#out" do
		it "renders arrays of nodes" do
			text = Markly.parse("Hello").first_child.first_child
			renderer.out([text])
			
			expect(renderer.output).to be == "Hello"
		end
	end
	
	with "#code_block" do
		it "must be implemented by subclasses" do
			code_block = Markly.parse("    Hello").first_child
			
			expect do
				renderer.render(code_block)
			end.to raise_exception(NotImplementedError)
		end
	end
	
end
