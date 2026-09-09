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

## Extensions

Markly parses standard CommonMark by default. GitHub Flavored Markdown syntax
and Markly-specific syntax are opt-in so applications can choose their accepted
Markdown dialect explicitly:

``` ruby
Markly.render_html(
	"| Name | Status |\n| --- | --- |\n| Markly | Ready |",
	extensions: [:table],
)
```

See [Extensions](../extensions/index) for the supported extensions, related
flags, and generated AST.

## Developing Locally

After cloning the repo:

	$ bake build test
