# Markly

A parser and abstract syntax tree for Markdown documents (CommonMark compatible) in Ruby. Originally forked from [CommonMarker](https://github.com/gjtorikian/commonmarker). It also includes extensions to the CommonMark spec as documented in the [GitHub Flavored Markdown spec](http://github.github.com/gfm/), such as support for tables, strikethroughs, and autolinking.

[![Development Status](https://github.com/ioquatix/markly/workflows/Test/badge.svg)](https://github.com/ioquatix/markly/actions?workflow=Test)

## Motivation

This code base was originally forked from [Commonmarker](https://github.com/gjtorikian/commonmarker) before they switched from `cmark-gfm` (C) to `comrak` (Rust). The original implementation provided access to the abstract syntaxtree (AST), which is useful for building tools on top of Markdown. The Rust implementation did not provide thisfunctionality, and so this fork was created to continue to provide these (and more) features.

It should be noted that `commonmarker` re-introduced AST access, but the original C implementation in this fork is [3-4x faster at processing Markdown into HTML](https://github.com/gjtorikian/commonmarker?tab=readme-ov-file#benchmarks) and has a more advanced HTML generation and AST processing features.

## Usage

Please see the [project documentation](https://ioquatix.github.io/markly/) for more details.

  - [Getting Started](https://ioquatix.github.io/markly/guides/getting-started/index) - This guide explains now to install and use Markly.

  - [Abstract Syntax Tree](https://ioquatix.github.io/markly/guides/abstract-syntax-tree/index) - This guide explains how to use Markly's abstract syntax tree (AST) to parse and manipulate Markdown documents.

  - [Headings](https://ioquatix.github.io/markly/guides/headings/index) - This guide explains how to work with headings in Markly, including extracting them for navigation and handling duplicate heading text.

## Releases

Please see the [project releases](https://ioquatix.github.io/markly/releases/index) for all releases.

### v0.15.1

  - Add agent context.

### v0.15.0

  - Introduced `Markly::Renderer::Headings` class for extracting headings from markdown documents with automatic duplicate ID resolution. When rendering HTML with `ids: true`, duplicate heading text now automatically gets unique IDs (`deployment`, `deployment-2`, `deployment-3`). The `Headings` class can also be used to extract headings for building navigation or table of contents.

### v0.14.0

  - Expose `Markly::Renderer::HTML.anchor_for` method to generate URL-safe anchors from headers.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
