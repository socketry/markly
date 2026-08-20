# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2020, by Garen Torikian.
# Copyright, 2015, by Nick Wellnhofer.
# Copyright, 2017, by Yuki Izumi.
# Copyright, 2017-2019, by Ashe Connor.
# Copyright, 2018, by Michael Camilleri.
# Copyright, 2020-2026, by Samuel Williams.

require_relative "generic"
require_relative "headings"

require "cgi/escape"

# Compatibility for older Ruby versions where escape_html alias doesn't exist:
unless CGI.respond_to?(:escape_html)
	require "cgi"
end

module Markly
	module Renderer
		# Renders Markdown node trees as HTML.
		class HTML < Generic
			# Initializes an HTML renderer.
			#
			# @parameter ids [Boolean] Whether to wrap headings in anchored sections.
			# @parameter headings [Markly::Renderer::Headings | Nil] A heading tracker to reuse.
			# @parameter tight [Boolean] Whether to render paragraphs tightly.
			# @option :flags [Integer] The enabled rendering flags.
			# @option :extensions [Array(Symbol)] The enabled extensions.
			def initialize(ids: false, headings: nil, tight: false, **options)
				super(**options)
				
				# Initialize heading tracker if IDs are enabled
				@headings = headings || (ids ? Headings.new : nil)
				
				@section = nil
				@tight = tight
				
				@footnotes = {}
			end
			
			# Renders a complete document and closes any generated sections.
			#
			# @parameter _ [Markly::Node] The document node.
			def document(_)
				@section = false
				super
				out("</ol>\n</section>\n") if @written_footnote_ix
				out("</section>") if @section
			end
			
			# Returns an escaped HTML id attribute for a heading node.
			#
			# @parameter node [Markly::Node] The heading node.
			# @returns [String | Nil] The id attribute when heading IDs are enabled.
			def id_for(node)
				if @headings
					anchor = @headings.anchor_for(node)
					return " id=\"#{CGI.escape_html anchor}\""
				end
			end
			
			# Generates a normalized anchor from a node's plain-text content.
			#
			# @parameter node [Markly::Node] The node to convert.
			# @returns [String] The normalized anchor.
			def self.anchor_for(node)
				# Convert to plaintext, strip trailing whitespace, convert to lowercase:
				text = node.to_plaintext.chomp.downcase
				
				# Replace sequences of whitespace with hyphens:
				text.gsub!(/\s+/, "-")
				
				return text
			end
			
			# Generates a normalized anchor from a node's plain-text content.
			#
			# @parameter node [Markly::Node] The node to convert.
			# @returns [String] The normalized anchor.
			def anchor_for(node)
				self.class.anchor_for(node)
			end
			
			# Renders a heading node, optionally wrapped in an anchored section.
			#
			# @parameter node [Markly::Node] The heading node.
			def header(node)
				block do
					if @headings
						out("</section>") if @section
						@section = true
						out("<section#{id_for(node)}>")
					end
					
					out("<h", node.header_level, "#{source_position(node)}>", :children, "</h", node.header_level, ">")
				end
			end
			
			# Renders a paragraph node.
			#
			# @parameter node [Markly::Node] The paragraph node.
			def paragraph(node)
				if @tight && node.parent.type != :blockquote
					out(:children)
				else
					block do
						container("<p#{source_position(node)}>", "</p>") do
							out(:children)
							if node.parent.type == :footnote_definition && node.next.nil?
								out(" ")
								out_footnote_backref
							end
						end
					end
				end
			end
			
			# Renders an ordered or unordered list node.
			#
			# @parameter node [Markly::Node] The list node.
			def list(node)
				old_tight = @tight
				@tight = node.list_tight
				
				block do
					if node.list_type == :bullet_list
						container("<ul#{source_position(node)}>\n", "</ul>") do
							out(:children)
						end
					else
						start = if node.list_start == 1
							"<ol#{source_position(node)}>\n"
						else
							"<ol start=\"#{node.list_start}\"#{source_position(node)}>\n"
						end
						container(start, "</ol>") do
							out(:children)
						end
					end
				end
				
				@tight = old_tight
			end
			
			# Renders a list-item node, including task-list attributes when present.
			#
			# @parameter node [Markly::Node] The list-item node.
			def list_item(node)
				block do
					tasklist_data = tasklist(node)
					container("<li#{source_position(node)}#{tasklist_data}>#{' ' if tasklist?(node)}", "</li>") do
						out(:children)
					end
				end
			end
			
			# Returns the HTML fragment required for a task-list item.
			#
			# @parameter node [Markly::Node] The list-item node.
			# @returns [String] The task-list fragment, or an empty string.
			def tasklist(node)
				return "" unless tasklist?(node)
				
				state = if checked?(node)
					'checked="" disabled=""'
				else
					'disabled=""'
				end
				"><input type=\"checkbox\" #{state} /"
			end
			
			# Renders a blockquote node.
			#
			# @parameter node [Markly::Node] The blockquote node.
			def blockquote(node)
				block do
					container("<blockquote#{source_position(node)}>\n", "</blockquote>") do
						out(:children)
					end
				end
			end
			
			# Renders a thematic-break node.
			#
			# @parameter node [Markly::Node] The thematic-break node.
			def hrule(node)
				block do
					out("<hr#{source_position(node)} />")
				end
			end
			
			# Renders a code block and its optional language metadata.
			#
			# @parameter node [Markly::Node] The code block node.
			def code_block(node)
				block do
					language = node.code_language
					
					if flag_enabled?(GITHUB_PRE_LANG)
						out("<pre#{source_position(node)}")
						out(' lang="', language, '"') if language
						out("><code>")
					else
						out("<pre#{source_position(node)}><code")
						if language
							out(' class="language-', language, '">')
						else
							out(">")
						end
					end
					out(escape_html(node.string_content))
					out("</code></pre>")
				end
			end
			
			# Renders or omits a raw block-level HTML node according to the flags.
			#
			# @parameter node [Markly::Node] The raw HTML node.
			def html(node)
				block do
					if flag_enabled?(UNSAFE)
						out(tagfilter(node.string_content))
					else
						out("<!-- raw HTML omitted -->")
					end
				end
			end
			
			# Renders or omits a raw inline HTML node according to the flags.
			#
			# @parameter node [Markly::Node] The raw inline HTML node.
			def inline_html(node)
				if flag_enabled?(UNSAFE)
					out(tagfilter(node.string_content))
				else
					out("<!-- raw HTML omitted -->")
				end
			end
			
			# Renders an emphasized inline node.
			#
			# @parameter node [Markly::Node] The emphasized node.
			def emph(node)
				out("<em>", :children, "</em>")
			end
			
			# Renders a strongly emphasized inline node.
			#
			# @parameter node [Markly::Node] The strong node.
			def strong(node)
				if node.parent.nil? || node.parent.type == node.type
					out(:children)
				else
					out("<strong>", :children, "</strong>")
				end
			end
			
			# Renders a link node with escaped destination and title attributes.
			#
			# @parameter node [Markly::Node] The link node.
			def link(node)
				out('<a href="', node.url.nil? ? "" : escape_href(node.url), '"')
				out(' title="', escape_html(node.title), '"') if node.title && !node.title.empty?
				out(">", :children, "</a>")
			end
			
			# Renders an image node with plain-text alternative content.
			#
			# @parameter node [Markly::Node] The image node.
			def image(node)
				out('<img src="', escape_href(node.url), '"')
				plain do
					out(' alt="', :children, '"')
				end
				out(' title="', escape_html(node.title), '"') if node.title && !node.title.empty?
				out(" />")
			end
			
			# Renders an escaped text node.
			#
			# @parameter node [Markly::Node] The text node.
			def text(node)
				out(escape_html(node.string_content))
			end
			
			# Renders an inline code node and its optional language metadata.
			#
			# @parameter node [Markly::Node] The inline code node.
			def code(node)
				language = node.code_language
				out("<code")
				out(' class="language-', language, '"') if language
				out(">")
				out(escape_html(node.string_content))
				out("</code>")
			end
			
			# Renders a hard line break.
			#
			# @parameter _node [Markly::Node] The line-break node.
			def linebreak(_node)
				out("<br />\n")
			end
			
			# Renders a soft line break according to the configured flags.
			#
			# @parameter _ [Markly::Node] The soft-break node.
			def softbreak(_)
				if flag_enabled?(HARD_BREAKS)
					out("<br />\n")
				elsif flag_enabled?(NO_BREAKS)
					out(" ")
				else
					out("\n")
				end
			end
			
			# Renders a table node and initializes its column alignments.
			#
			# @parameter node [Markly::Node] The table node.
			def table(node)
				@alignments = node.table_alignments
				@needs_close_tbody = false
				out("<table#{source_position(node)}>\n", :children)
				out("</tbody>\n") if @needs_close_tbody
				out("</table>\n")
			end
			
			# Renders a table-header row.
			#
			# @parameter node [Markly::Node] The table-header node.
			def table_header(node)
				@column_index = 0
				
				@in_header = true
				out("<thead>\n<tr#{source_position(node)}>\n", :children, "</tr>\n</thead>\n")
				@in_header = false
			end
			
			# Renders a table row, opening the table body when necessary.
			#
			# @parameter node [Markly::Node] The table-row node.
			def table_row(node)
				@column_index = 0
				if !@in_header && !@needs_close_tbody
					@needs_close_tbody = true
					out("<tbody>\n")
				end
				out("<tr#{source_position(node)}>\n", :children, "</tr>\n")
			end
			
			# @constant [Hash(Symbol, String)] HTML attributes for table-cell alignments.
			TABLE_CELL_ALIGNMENT = {
				left: ' align="left"',
				right: ' align="right"',
				center: ' align="center"'
			}.freeze
			
			# Renders a table cell using the current column alignment.
			#
			# @parameter node [Markly::Node] The table-cell node.
			def table_cell(node)
				align = TABLE_CELL_ALIGNMENT.fetch(@alignments[@column_index], "")
				out(@in_header ? "<th#{align}#{source_position(node)}>" : "<td#{align}#{source_position(node)}>", :children, @in_header ? "</th>\n" : "</td>\n")
				@column_index += 1
			end
			
			# Renders a strikethrough node.
			#
			# @parameter _ [Markly::Node] The strikethrough node.
			def strikethrough(_)
				out("<del>", :children, "</del>")
			end
			
			# Renders a footnote reference linking to its definition.
			#
			# @parameter node [Markly::Node] The footnote-reference node.
			def footnote_reference(node)
				label = node.parent_footnote_def.string_content
				
				out("<sup class=\"footnote-ref\"><a href=\"#fn-#{label}\" id=\"fnref-#{label}\" data-footnote-ref>#{node.string_content}</a></sup>")
				# out(node.to_html)
			end
			
			# Renders a footnote definition and records its backlink target.
			#
			# @parameter node [Markly::Node] The footnote-definition node.
			def footnote_definition(node)
				unless @footnote_ix
					out("<section class=\"footnotes\" data-footnotes>\n<ol>\n")
					@footnote_ix = 0
				end
				
				@footnote_ix += 1
				label = node.string_content
				@footnotes[@footnote_ix] = label
				
				out("<li id=\"fn-#{label}\">\n", :children)
				out("\n") if out_footnote_backref
				out("</li>\n")
				# </ol>
				# </section>
			end
			
			private
			
			def out_footnote_backref
				return false if @written_footnote_ix == @footnote_ix
				
				@written_footnote_ix = @footnote_ix
				
				out("<a href=\"#fnref-#{@footnotes[@footnote_ix]}\" class=\"footnote-backref\" data-footnote-backref data-footnote-backref-idx=\"#{@footnote_ix}\" aria-label=\"Back to reference #{@footnote_ix}\">↩</a>")
				true
			end
			
			def tasklist?(node)
				node.type_string == "tasklist"
			end
			
			def checked?(node)
				node.tasklist_item_checked?
			end
		end
	end
end
