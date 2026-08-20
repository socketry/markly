# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025-2026, by Samuel Williams.

module Markly
	module Renderer
		# Extracts headings from a markdown document with unique anchor IDs.
		# Handles duplicate heading text by appending counters (e.g., "deployment", "deployment-2", "deployment-3").
		class Headings
			# Initializes an empty heading-anchor registry.
			def initialize
				@ids = {}
			end
			
			# Generate a unique anchor for a node.
			# @parameter node [Markly::Node] The heading node
			# @returns [String] A unique anchor ID
			def anchor_for(node)
				base = base_anchor_for(node)
				
				if @ids.key?(base)
					@ids[base] += 1
					"#{base}-#{@ids[base]}"
				else
					@ids[base] = 1
					base
				end
			end
			
			# Extract all headings from a document root with unique anchors.
			# @parameter root [Markly::Node] The document root node
			# @parameter min_level [Integer] Minimum heading level to extract (default: 1)
			# @parameter max_level [Integer] Maximum heading level to extract (default: 6)
			# @returns [Array<Heading>] Array of heading objects with unique anchors
			def extract(root, min_level: 1, max_level: 6)
				headings = []
				root.walk do |node|
					if node.type == :header
						level = node.header_level
						next if level < min_level || level > max_level
						
						headings << Heading.new(
							node: node,
							level: level,
							text: node.to_plaintext.chomp,
							anchor: anchor_for(node)
						)
					end
				end
				headings
			end
			
			# Class method for convenience - creates a new instance and extracts headings.
			# @parameter root [Markly::Node] The document root node
			# @parameter min_level [Integer] Minimum heading level to extract (default: 1)
			# @parameter max_level [Integer] Maximum heading level to extract (default: 6)
			# @returns [Array<Heading>] Array of heading objects with unique anchors
			def self.extract(root, min_level: 1, max_level: 6)
				new.extract(root, min_level: min_level, max_level: max_level)
			end
			
			private
			
			# Generate a base anchor from a node's text content.
			# @parameter node [Markly::Node] The heading node
			# @returns [String] The base anchor (lowercase, hyphenated)
			def base_anchor_for(node)
				text = node.to_plaintext.chomp.downcase
				text.gsub(/\s+/, "-")
			end
		end
		
		# Represents a heading extracted from a document.
		# @attribute node [Markly::Node] The original heading node
		# @attribute level [Integer] The heading level (1-6)
		# @attribute text [String] The plain text content of the heading
		# @attribute anchor [String] The unique anchor ID for this heading
		Heading = Struct.new(:node, :level, :text, :anchor, keyword_init: true)
	end
end
