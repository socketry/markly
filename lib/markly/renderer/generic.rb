# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2019, by Garen Torikian.
# Copyright, 2016-2017, by Yuki Izumi.
# Copyright, 2020-2026, by Samuel Williams.

require "set"
require "stringio"

module Markly
	# @namespace
	module Renderer
		# Base class for renderers implemented in Ruby.
		class Generic
			# Initializes a renderer with rendering flags and extensions.
			#
			# @parameter flags [Integer] The enabled rendering flags.
			# @parameter extensions [Array(Symbol)] The enabled extensions.
			def initialize(flags: DEFAULT, extensions: [])
				@flags = flags
				@stream = StringIO.new(+"")
				@in_tight = false
				@in_plain = false
				@tagfilter = extensions.include?(:tagfilter)
			end
			
			# @attribute [Boolean] Whether the renderer is inside a tight container.
			attr_accessor :in_tight
			
			# @attribute [Boolean] Whether the renderer is emitting plain text.
			attr_accessor :in_plain
			
			# Writes strings, nodes, arrays of nodes, or child-node markers to the output.
			#
			# @parameter args [Array(Object)] Values to append or render.
			def out(*args)
				args.each do |arg|
					if arg == :children
						@node.each{|child| out(child)}
					elsif arg.is_a?(Array)
						arg.each{|x| render(x)}
					elsif arg.is_a?(Node)
						render(arg)
					else
						@stream.write(arg)
					end
				end
			end
			
			# Renders a node and returns the completed output for document nodes.
			#
			# @parameter node [Markly::Node] The node to render.
			# @returns [String | Nil] The output string when rendering a document.
			def render(node)
				@node = node
				if node.type == :document
					document(node)
					@stream.string
				elsif @in_plain && node.type != :text && node.type != :softbreak
					node.each{|child| render(child)}
				else
					send(node.type, node)
				end
			end
			
			# Renders a document node and all of its children.
			#
			# @parameter _node [Markly::Node] The document node.
			def document(_node)
				out(:children)
			end
			
			# Renders a code block node.
			#
			# Subclasses should override this callback.
			# @parameter _node [Markly::Node] The code block node.
			def code_block(_node)
				raise NotImplementedError, "#{self.class} must implement #code_block"
			end
			
			# Ignores reference-definition nodes, which have no direct output.
			#
			# @parameter _node [Markly::Node] The reference-definition node.
			def reference_def(_node); end
			
			# Writes a newline unless the output is empty or already ends with one.
			#
			def cr
				return if @stream.string.empty? || @stream.string[-1] == "\n"
				
				out("\n")
			end
			
			# Renders a block surrounded by normalized newlines.
			#
			# @yields {|| ...} The block content to render.
			def block
				cr
				yield
				cr
			end
			
			# Renders content between opening and closing strings.
			#
			# @parameter starter [String] The opening output.
			# @parameter ender [String] The closing output.
			# @yields {|| ...} The container content to render.
			def container(starter, ender)
				out(starter)
				yield
				out(ender)
			end
			
			# Renders a block in plain-text mode, suppressing structural markup.
			#
			# @yields {|| ...} The content to render as plain text.
			def plain
				old_in_plain = @in_plain
				@in_plain = true
				yield
				@in_plain = old_in_plain
			end
			
			private
			
			def escape_href(str)
				@node.html_escape_href(str)
			end
			
			def escape_html(str)
				@node.html_escape_html(str)
			end
			
			def tagfilter(str)
				if @tagfilter
					str.gsub(
						%r{
							<
							(
							title|textarea|style|xmp|iframe|
							noembed|noframes|script|plaintext
							)
							(?=\s|>|/>)
						}xi,
						'&lt;\1'
					)
				else
					str
				end
			end
			
			def source_position(node)
				return "" unless flag_enabled?(SOURCE_POSITION)
				
				s = node.source_position
				" data-sourcepos=\"#{s[:start_line]}:#{s[:start_column]}-" \
					"#{s[:end_line]}:#{s[:end_column]}\""
			end
			
			def flag_enabled?(flag)
				(@flags & flag) != 0
			end
		end
	end
end
