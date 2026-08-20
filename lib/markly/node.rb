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
		
		# Duplicate the current node and all children.
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
		
		# Public: An iterator that "walks the tree," descending into children recursively.
		#
		# block - A {Proc} representing the action to take for each child
		def walk(&block)
			return enum_for(:walk) unless block_given?
			
			yield self
			each do |child|
				child.walk(&block)
			end
		end
		
		# Public: Convert the node to an HTML string.
		#
		# flags - A {Symbol} or {Array of Symbol}s indicating the render options
		# extensions - An {Array of Symbol}s indicating the extensions to use
		#
		# Returns a {String}.
		def to_html(flags: DEFAULT, extensions: [])
			_render_html(flags, extensions).force_encoding("utf-8")
		end
		
		# Public: Convert the node to a CommonMark string.
		#
		# flags - A {Symbol} or {Array of Symbol}s indicating the render options
		# width - Column to wrap the output at
		#
		# Returns a {String}.
		def to_commonmark(flags: DEFAULT, width: 0)
			_render_commonmark(flags, width).force_encoding("utf-8")
		end
		
		alias to_markdown to_commonmark
		
		# Public: Returns the language identifier from the code info string.
		#
		# Returns a {String}, or `nil` when no language is present.
		def code_language
			code_info.split(/\s+/, 2).first
		end
		
		# Public: Convert the node to a plain text string.
		#
		# flags - A {Symbol} or {Array of Symbol}s indicating the render options
		# width - Column to wrap the output at
		#
		# Returns a {String}.
		def to_plaintext(flags: DEFAULT, width: 0)
			_render_plaintext(flags, width).force_encoding("utf-8")
		end
		
		# Public: Iterate over the children (if any) of the current pointer.
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
		# @returns [Markly::Node, nil] The matching header, if present.
		def find_header(title)
			each do |child|
				if child.type == :header && child.first_child.string_content == title
					return child
				end
			end
		end
		
		# Delete all nodes until the block returns true.
		#
		# @returns [Markly::Node] the node that returned true.
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
		# @parameter new_node [Markly::Node] the node to replace the section with.
		# @parameter replace_header [Boolean] whether to replace the header itself or not.
		# @parameter remove_subsections [Boolean] whether to remove subsections or not.
		def replace_section(new_node, replace_header: true, remove_subsections: true)
			# Delete until the next heading:
			self.next&.delete_until do |node|
				node.type == :header && (!remove_subsections || node.header_level <= self.header_level)
			end
			
			self.append_after(new_node) if new_node
			self.delete if replace_header
		end
		
		# Finds the next sibling heading.
		#
		# @returns [Markly::Node, nil] The next heading, if present.
		def next_heading
			current = self.next
			while current
				if current.type == :heading
					return current
				end
				current = current.next
			end
		end
		
		# Append the given node after the current node.
		#
		# It's okay to provide a document node, its children will be appended.
		#
		# @parameter node [Markly::Node] the node to append.
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
		# @parameter node [Markly::Node] the node to append.
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
		# @returns [Markly::Node] the fragment.
		def extract_children
			fragment = Markly::Node.new(:custom_inline)
			
			while child = self.first_child
				fragment.append_child(child)
			end
			
			fragment
		end
		
	end
end
