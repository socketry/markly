# Releases

## Unreleased

  - Update `cmark-gfm` from upstream, including a denial-of-service fix for tables with a large number of autocompleted cells, corrected `end_line` source positions for single-line and multi-line HTML blocks, and a fix for trailing newlines when rendering inline nodes.
  - Add support for front matter (`CMARK_OPT_FRONT_MATTER`): a `---` delimited block at the start of a document is captured as a `CMARK_NODE_FRONT_MATTER` node.  The raw content is available via `node.string_content` and an optional format hint (e.g. `"yaml"`, `"toml"`) via `node.fence_info`.
  - Allow `:` in HTML tag names to support XML namespace prefixes (e.g. `<svg:circle>`, `<xhtml:div>`).

## v0.15.1

  - Add agent context.

## v0.15.0

  - Introduced `Markly::Renderer::Headings` class for extracting headings from markdown documents with automatic duplicate ID resolution. When rendering HTML with `ids: true`, duplicate heading text now automatically gets unique IDs (`deployment`, `deployment-2`, `deployment-3`). The `Headings` class can also be used to extract headings for building navigation or table of contents.

## v0.14.0

  - Expose `Markly::Renderer::HTML.anchor_for` method to generate URL-safe anchors from headers.
