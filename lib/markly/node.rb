# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016-2019, by Garen Torikian.
# Copyright, 2016-2017, by Yuki Izumi.
# Copyright, 2017, by Goro Fuji.
# Copyright, 2018, by Jerry van Leeuwen.
# Copyright, 2020-2026, by Samuel Williams.
# Copyright, 2025, by Olle Jonsson.

require_relative "node/inspect"

module Markly
	# Represents a node in a parsed Markdown document tree.
	class Node
		include Enumerable
		include Inspect
		
		# Duplicate the current node and all its children.
		#
		# @returns [Markly::Node] The duplicated node tree.
		def dup
			# This is a bit crazy, but it's the best I can come up with right now:
			node = Markly.parse(self.to_markdown)
			
			# If we aren't duplicating a document, we return `first_child` as the root will be a document node:
			if self.type == :document
				return node
			else
				return node.first_child
			end
		end
		
		# Walk the node tree recursively.
		#
		# @yields {|node| ...} Each node in depth-first order, including this node.
		# 	@parameter node [Markly::Node] The current node.
		# @returns [Enumerator | Nil] An enumerator when no block is given.
		def walk(&block)
			return enum_for(:walk) unless block_given?
			
			yield self
			each do |child|
				child.walk(&block)
			end
		end
		
		# Convert the node to an HTML string.
		#
		# @parameter flags [Integer] The enabled rendering flags.
		# @parameter extensions [Array(Symbol)] The extensions to enable.
		# @returns [String] The rendered HTML.
		def to_html(flags: DEFAULT, extensions: [])
			_render_html(flags, extensions).force_encoding("utf-8")
		end
		
		# Convert the node to a CommonMark string.
		#
		# @parameter flags [Integer] The enabled rendering flags.
		# @parameter width [Integer] The column at which to wrap output, or `0` to disable wrapping.
		# @returns [String] The rendered CommonMark text.
		def to_commonmark(flags: DEFAULT, width: 0)
			_render_commonmark(flags, width).force_encoding("utf-8")
		end
		
		alias to_markdown to_commonmark
		
		# Return the language identifier from the code info string.
		#
		# @returns [String | Nil] The language identifier, or `nil` when none is present.
		def code_language
			code_info.split(/\s+/, 2).first
		end
		
		# Convert the node to a plain-text string.
		#
		# @parameter flags [Integer] The enabled rendering flags.
		# @parameter width [Integer] The column at which to wrap output, or `0` to disable wrapping.
		# @returns [String] The rendered plain text.
		def to_plaintext(flags: DEFAULT, width: 0)
			_render_plaintext(flags, width).force_encoding("utf-8")
		end
		
		# Iterate over the direct children of this node.
		#
		# @yields {|child| ...} Each direct child of this node.
		# 	@parameter child [Markly::Node] The current child node.
		# @returns [Enumerator | Nil] An enumerator when no block is given.
		def each
			return enum_for(:each) unless block_given?
			
			child = first_child
			while child
				next_child = child.next
				yield child
				child = next_child
			end
		end
		
		# Finds a direct child header with the given text.
		#
		# @parameter title [String] The header text to match.
		# @returns [Markly::Node | Nil] The matching header, if present.
		def find_header(title)
			each do |child|
				if child.type == :header && child.first_child.string_content == title
					return child
				end
			end
		end
		
		# Delete all nodes until the block returns true.
		#
		# @yields {|node| ...} Each node before it is deleted.
		# 	@parameter node [Markly::Node] The current node.
		# @returns [Markly::Node | Nil] The node for which the block returned `true`, if any.
		def delete_until
			current = self
			while current
				return current if yield(current)
				next_node = current.next
				current.delete
				current = next_node
			end
		end
		
		# Replace a section (header + content) with a new node.
		#
		# @parameter new_node [Markly::Node | Nil] The node with which to replace the section.
		# @parameter replace_header [Boolean] Whether to replace the header itself.
		# @parameter remove_subsections [Boolean] Whether to remove subsections.
		def replace_section(new_node, replace_header: true, remove_subsections: true)
			# Delete until the next heading:
			self.next&.delete_until do |node|
				node.type == :header && (!remove_subsections || node.header_level <= self.header_level)
			end
			
			self.append_after(new_node) if new_node
			self.delete if replace_header
		end
		
		# Finds the next sibling header.
		#
		# @returns [Markly::Node | Nil] The next header, if present.
		def next_header
			current = self.next
			while current
				if current.type == :header
					return current
				end
				current = current.next
			end
		end
		
		# An alias for {ruby Markly::Node#next_header}.
		alias next_heading next_header
		
		# Append the given node after the current node.
		#
		# It's okay to provide a document node, its children will be appended.
		#
		# @parameter node [Markly::Node] The node to append.
		def append_after(node)
			if node.type == :document
				node = node.first_child
			end
			
			current = self
			while node
				next_node = node.next
				current.insert_after(node)
				current = node
				node = next_node
			end
		end
		
		# Append the given node before the current node.
		#
		# It's okay to provide a document node, its children will be appended.
		#
		# @parameter node [Markly::Node] The node to append.
		def append_before(node)
			if node.type == :document
				node = node.first_child
			end
			
			current = self
			while node
				next_node = node.next
				current.insert_before(node)
				node = next_node
			end
		end
		
		# Extract the children as a fragment.
		#
		# @returns [Markly::Node] The fragment.
		def extract_children
			fragment = Markly::Node.new(:custom_inline)
			
			while child = self.first_child
				fragment.append_child(child)
			end
			
			fragment
		end
		
	end
end
