# Extensions

This guide explains how to enable and use Markly's Markdown extensions.

## Choosing a Markdown Dialect

Markly parses standard CommonMark by default. Extensions change which syntax is
recognized, so applications should enable them explicitly and consistently.
This is especially important when several components parse or render the same
document.

Pass extension names as symbols using the `extensions:` keyword:

``` ruby
EXTENSIONS = %i[table tasklist strikethrough autolink].freeze

html = Markly.render_html(markdown, extensions: EXTENSIONS)
```

When parsing and rendering separately, use the same configuration at both
boundaries:

``` ruby
document = Markly.parse(markdown, extensions: EXTENSIONS)
html = document.to_html(extensions: EXTENSIONS)
```

Extension names must be symbols. A string such as `"table"` raises `TypeError`,
and an unknown symbol raises `ArgumentError`.

## GitHub Flavored Markdown Extensions

Markly includes the five syntax extensions defined by GitHub Flavored Markdown.
None are enabled by default.

### Tables

The `:table` extension recognizes a paragraph followed by a delimiter row as a
table. Colons in the delimiter row specify column alignment:

``` ruby
markdown = <<~MARKDOWN
	| Package | Status |
	| :--- | ---: |
	| Markly | Ready |
MARKDOWN

document = Markly.parse(markdown, extensions: [:table])
table = document.first_child

table.type
# => :table

table.table_alignments
# => [:left, :right]
```

The table AST contains `:table`, `:table_header`, `:table_row`, and
`:table_cell` nodes. By default, HTML rendering uses `align` attributes for
aligned cells. Pass `Markly::TABLE_PREFER_STYLE_ATTRIBUTES` when rendering to
use `style="text-align: ..."` instead:

``` ruby
document.to_html(
	flags: Markly::TABLE_PREFER_STYLE_ATTRIBUTES,
	extensions: [:table],
)
```

### Task Lists

The `:tasklist` extension recognizes checked and unchecked list items:

``` markdown
- [x] Parse Markdown
- [ ] Render HTML
```

Task-list state is available on the list-item node and can be changed before
rendering:

``` ruby
document = Markly.parse("- [x] Parse Markdown", extensions: [:tasklist])
item = document.first_child.first_child

item.tasklist_item_checked?
# => true

item.tasklist_item_checked = false
```

### Strikethrough

The `:strikethrough` extension renders strikethrough text using `<del>`:

``` ruby
Markly.render_html("~~obsolete~~", extensions: [:strikethrough])
# => "<p><del>obsolete</del></p>\n"
```

Pass `Markly::STRIKETHROUGH_DOUBLE_TILDE` while parsing to accept only spans
surrounded by exactly two tildes. This is useful when compatibility requires
single or longer runs of tildes to remain literal:

``` ruby
Markly.render_html(
	"~one~ ~~two~~ ~~~three~~~",
	flags: Markly::STRIKETHROUGH_DOUBLE_TILDE,
	extensions: [:strikethrough],
)
# => "<p>~one~ <del>two</del> ~~~three~~~</p>\n"
```

### Autolinks

The `:autolink` extension turns plain URLs and email addresses into links
without requiring angle brackets or Markdown link syntax:

``` ruby
Markly.render_html(
	"Visit https://socketry.io or email hello@example.com.",
	extensions: [:autolink],
)
```

Use this extension when rendering prose where authors expect GitHub-style link
detection. Leave it disabled when plain URL-like text must remain unchanged.

### Tag Filtering

The `:tagfilter` extension escapes the raw HTML tags prohibited by the GitHub
Flavored Markdown specification. It is typically combined with
`Markly::UNSAFE`, which otherwise permits raw HTML:

``` ruby
Markly.render_html(
	"<script>alert('no')</script><strong>yes</strong>",
	flags: Markly::UNSAFE,
	extensions: [:tagfilter],
)
```

Tag filtering is not a general-purpose HTML sanitizer. It filters the specific
tag names required by the GFM specification, while other raw HTML remains
available when `Markly::UNSAFE` is enabled. Sanitize untrusted HTML separately
when the application requires a stricter policy.

## Markly Syntax Features

Markly also provides syntax features that are not named GFM extensions. Enable
these with parser flags rather than adding names to `extensions:`.

### Front Matter

`Markly::FRONT_MATTER` recognizes a `---` delimited block only at the beginning
of a document:

``` ruby
markdown = <<~MARKDOWN
	--- yaml
	title: Extensions
	---
	# Document
MARKDOWN

document = Markly.parse(markdown, flags: Markly::FRONT_MATTER)
front_matter = document.first_child

front_matter.type
# => :front_matter

front_matter.string_content
# => "title: Extensions\n"

front_matter.code_info
# => "yaml"
```

Front matter is omitted from HTML and plain-text output. Markly exposes its raw
contents but does not interpret YAML, TOML, or any other format. Treat the
contents as untrusted input and parse them according to the application's own
policy.

The closing delimiter must be an exact `---` line. If it is missing, the rest
of the document belongs to the front-matter node.

### Inline Code Information

`Markly::INLINE_CODE_INFO` recognizes a language prefix immediately before an
inline code span:

``` ruby
document = Markly.parse(
	"ruby:`Object.new`",
	flags: Markly::INLINE_CODE_INFO,
)
code = document.first_child.first_child

code.code_info
# => "ruby"

code.code_language
# => "ruby"

document.to_html
# => "<p><code class=\"language-ruby\">Object.new</code></p>\n"
```

Without the flag, the prefix remains ordinary text. Inline code information is
a single language token; richer code-block information belongs on a fenced code
block instead.

### Indented HTML Blocks

CommonMark ends type 6 and 7 HTML blocks at the first blank line. This can be
surprising when a large HTML fragment is formatted with blank lines between
consistently indented child elements: the following child is parsed as Markdown,
often as an indented code block.

`Markly::INDENTED_HTML_BLOCKS` allows those HTML blocks to continue across blank
lines when their content establishes and preserves indentation:

``` ruby
markdown = <<~MARKDOWN
	<div class="diagram">
		<div class="request">GET /slides</div>

		<div class="response">200 OK</div>
	</div>
MARKDOWN

Markly.render_html(
	markdown,
	parse_flags: Markly::INDENTED_HTML_BLOCKS,
	render_flags: Markly::UNSAFE,
)
```

The indentation may be established after an initial blank line. Once
established, the first nonblank line with less indentation ends the HTML block.
This keeps the extension deterministic without attempting to match or interpret
HTML tags.

This option deliberately changes CommonMark parsing and is disabled by default.
Use it for trusted, author-written documents where multiline HTML is a supported
part of the Markdown dialect. `Markly::UNSAFE` is still required when rendering
the resulting raw HTML.

### Code Block Metadata

`Node#code_info` is the general information-string accessor for fenced code
blocks and front matter. `Node#code_language` returns the first token of that
information string.

For a fenced code block, `Node#fence` returns a {ruby Markly::Node::Fence}
containing the fence character, length, and indentation:

``` ruby
block = Markly.parse("  ~~~~ ruby\n  Object.new\n  ~~~~").first_child

block.code_info
# => "ruby"

block.fence
# => #<struct Markly::Node::Fence character="~", length=4, indent=2>
```

Indented code blocks and other node types return `nil` from `Node#fence`.
