# Getting Started

This guide explains now to install and use Markly.

## Installation 

Add the gem to your project:

	$ bundle add markly

## Usage

Markly's most basic usage is to convert Markdown to HTML. You can do this in a few ways:

~~~ ruby
require 'markly'

Markly.render_html('Hi *there*')
# <p>Hi <em>there</em></p>\n
~~~

You can also parse a string to receive a `Document` node. You can then print that node to HTML, iterate over the children, and other fun node stuff. For example:

~~~ ruby
require 'markly'

document = Markly.parse('*Hello* world')
puts(document.to_html) # <p>Hi <em>there</em></p>\n

document.walk do |node|
	puts node.type # [:document, :paragraph, :text, :emph, :text]
end
~~~

## Options

Markly accepts integer flags which control how the Markdown is parsed and rendered.

### Parse Options

| Name                                 | Description
| ------------------------------------ | -----------
| `Markly::DEFAULT`                    | The default parsing system.
| `Markly::UNSAFE`                     | Allow raw/custom HTML and unsafe links.
| `Markly::FRONT_MATTER`               | Parse front matter at the start of the document.
| `Markly::FOOTNOTES`                  | Parse footnotes.
| `Markly::INLINE_CODE_INFO`           | Parse language prefixes such as `ruby:` on inline code spans.
| `Markly::LIBERAL_HTML_TAG`           | Support liberal parsing of inline HTML tags.
| `Markly::SMART`                      | Use smart punctuation (curly quotes, etc.).
| `Markly::STRIKETHROUGH_DOUBLE_TILDE` | Parse strikethroughs by double tildes (compatibility with [redcarpet](https://github.com/vmg/redcarpet))
| `Markly::VALIDATE_UTF8`              | Replace illegal sequences with the replacement character `U+FFFD`.

### Render Options

| Name                                    | Description                                                     |
| --------------------------------------- | --------------------------------------------------------------- |
| `Markly::DEFAULT`                       | The default rendering system.                                   |
| `Markly::UNSAFE`                        | Allow raw/custom HTML and unsafe links.                         |
| `Markly::GITHUB_PRE_LANG`               | Use GitHub-style `<pre lang>` for fenced code blocks.           |
| `Markly::HARD_BREAKS`                   | Treat `\n` as hardbreaks (by adding `<br/>`).                   |
| `Markly::NO_BREAKS`                     | Translate `\n` in the source to a single whitespace.            |
| `Markly::SOURCE_POSITION`               | Include source position in rendered HTML.                       |
| `Markly::TABLE_PREFER_STYLE_ATTRIBUTES` | Use `style` insted of `align` for table cells.                  |
| `Markly::FULL_INFO_STRING`              | Include full info strings of code blocks in separate attribute. |

### Passing Options

To apply a single option, pass it in as a flags option:

``` ruby
Markly.parse("\"Hello,\" said the spider.", flags: Markly::SMART)
# <p>“Hello,” said the spider.</p>\n
```

To have multiple options applied, `|` (or) the flags together:

``` ruby
Markly.render_html("\"'Shelob' is my name.\"", flags: Markly::HARD_BREAKS|Markly::SOURCE_POSITION)
```

Inline code language prefixes are opt-in. The language is available through
`Node#code_info` and is rendered as a `language-...` class:

``` ruby
document = Markly.parse("ruby:`Object.new`", flags: Markly::INLINE_CODE_INFO)
code = document.first_child.first_child

code.code_info
# => "ruby"

code.code_language
# => "ruby"

document.to_html
# => <p><code class="language-ruby">Object.new</code></p>
```

`Node#code_info` is also the general info-string accessor for fenced code
blocks and front matter. `Node#code_language` returns the first token of that
info string, while `Node#fence_info` remains available for compatibility on
those block nodes.

For a fenced code block, `Node#fence` returns a `Node::Fence` structure with
the fence character, length, and indentation:

``` ruby
block = Markly.parse("  ~~~~ ruby\n  Object.new\n  ~~~~").first_child

block.fence
# => #<struct Markly::Node::Fence character="~", length=4, indent=2>
```

Indented code blocks and other node types return `nil`.

## Extensions

Both `render_html` and `parse` take an optional `extensions:` argument defining the extensions you want enabled as your CommonMark document is being processed:

``` ruby
Markly.render_html("<script>hi</script>", flags: Markly::UNSAFE, extensions: [:tagfilter])
```

The documentation for these extensions are [defined in this spec](https://github.github.com/gfm/), and the rationale is provided [in this blog post](https://githubengineering.com/a-formal-spec-for-github-markdown/).

The available extensions are:

  - `:table` - This provides support for tables.
  - `:tasklist` - This provides support for task list items.
  - `:strikethrough` - This provides support for strikethroughs.
  - `:autolink` - This provides support for automatically converting URLs to anchor tags.
  - `:tagfilter` - This escapes [several "unsafe" HTML tags](https://github.github.com/gfm/#disallowed-raw-html-extension-), causing them to not have any effect.

## Developing Locally

After cloning the repo:

	$ bake build test
